require 'rake/tasklib'
require 'rake/clean'
require 'fileutils'

# rubocop:disable Style/FormatStringToken, Style/ClassAndModuleChildren
# rubocop:disable Metrics/LineLength, Metrics/MethodLength, Metrics/ClassLength

module SIMP; end
module SIMP::RPM; end

# Download, munge, stage, and build RPMs from .spec files
#
# Features:
# - downloads sources using `git clone` OR `curl`
# - run post-clone commands for munging or additional prep
# - scaffold rpmbuild trees
# - build tar, srpm, and rpm files
# - process influence by steps in a yaml config file
#
class SIMP::RPM::SpecBuilder < Rake::TaskLib
  include (Rake.verbose == true ? FileUtils::Verbose : FileUtils)

  def initialize(config_hash)
    @things_to_download = config_hash
    @dirs = {}
    @dirs[:dist]               = File.expand_path('dist')
    @dirs[:rpmbuild]           = File.expand_path('rpmbuild', @dirs[:dist])
    @dirs[:tmp]                = File.expand_path('tmp', @dirs[:dist])
    @dirs[:logs]               = File.expand_path('logs', @dirs[:tmp])
    @dirs[:rpmbuild_sources]   = File.expand_path('SOURCES', @dirs[:rpmbuild])
    @dirs[:rpmbuild_build]     = File.expand_path('BUILD', @dirs[:rpmbuild])
    @dirs[:rpmbuild_buildroot] = File.expand_path('BUILDROOT', @dirs[:rpmbuild])
    @dirs[:extra_sources_dir]  = File.expand_path('extra_sources', @dirs[:dist])
  end

  # Download and untar a tarball into a new directory
  def dl_untar(url, dst)
    mkdir_p dst
    Dir.chdir dst
    sh "curl -sSfL '#{url}' | tar zxvf -"
  end

  # clone a git repo into a new directory
  def git_clone(url, ref, dst)
    sh "git clone '#{url}' -b '#{ref}' '#{dst}'"
  end

  # Downloads via git clone or URL for targz
  def download(url, dir, type, version = nil, _extras = nil)
    url = url.gsub('%{VERSION}', version) if version
    Dir.chdir File.dirname(dir)
    if File.directory? dir
      warn "WARNING: path '#{dir}' already exists; aborting download"
      return dir
    end
    case type
    when :targz
      dl_untar url, dir
    when :gitrepo
      git_clone url, version, dir
    else
      raise "ERROR: :type is not :targz or :gitrepo (#{dl_info.inspect})"
    end
    dir
  end

  # Return information from an RPM .spec file
  # @return Hash spec info
  def spec_info(spec_file)
    info = {}
    cmd = "rpm -q --define 'debug_package %{nil}' --queryformat '%{NAME} %{VERSION} %{RELEASE} %{ARCH}\n' --specfile '#{spec_file}'"
    info[:basename], info[:version], info[:release], info[:arch] = `#{cmd}`.strip.split
    info[:ver_name] = "#{info[:basename]}-#{info[:version]}"
    info
  end

  def mk_dirs
    @dirs.each do |_k, dir|
      mkdir_p dir
    end
  end

  def _download(spec, cwd)
    Dir.chdir File.dirname(spec)
    info      = spec_info(spec)
    dl_dir    = File.expand_path("dist/#{info[:ver_name]}")
    dl_info   = @things_to_download[info[:basename]]

    # download the source0
    download(dl_info[:url], dl_dir, dl_info[:type], dl_info[:version])

    # download extras (source1, etc)
    Dir.chdir dl_dir
    cmds = dl_info.fetch(:extras, {}).fetch(:post_dl, [])
    cmds.each do |cmd|
      sh cmd.gsub('%{SOURCES_DIR}', @dirs[:extra_sources_dir])
        .gsub('%{DOWNLOAD_DIR}', dl_dir)
            .gsub('%{PROJECT_DIR}', cwd)
    end
  end

  # All steps done in one go, because there's no time to be fancy this sprint
  # TODO: break up steps
  def build_full_rpm(spec, cwd)
    Dir.chdir cwd
    spec_path = File.expand_path(spec)
    info      = spec_info(spec_path)
    dl_dir    = File.expand_path((info[:ver_name]).to_s, @dirs[:dist])

    Dir.chdir File.dirname(dl_dir)
    tar_file = File.join(@dirs[:rpmbuild_sources], "#{info[:ver_name]}.tar.gz")
    puts "============================ TAR ============================\n" * 7
    # NOTE: We don't use ` --exclude-vcs` by default.  Some build scripts
    #       (notably: the tpm2-* projects' ./bootstrap) get cranky without a
    #       .git/ directory
    tar_cmd = "tar --owner 0 --group 0 -cpzf #{tar_file} #{File.basename dl_dir}"
    sh tar_cmd
    FileUtils.cp_r(File.join(@dirs[:extra_sources_dir], '.'), @dirs[:rpmbuild_sources])

    Dir.chdir cwd
    puts "============================ SRPM ============================\n" * 7
    srpm_cmd = "RPM_BUILD_ROOT=#{@dirs[:rpmbuild_buildroot]} "\
      "rpmbuild -D 'debug_package %{nil}' " \
      "-D '_topdir #{@dirs[:rpmbuild]}' " \
      "-D '_rpmdir #{@dirs[:dist]}' -D '_srcrpmdir #{@dirs[:dist]}' " \
      "-D '_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm' " \
      " -v -bs '#{spec_path}' " \
      "|& tee #{@dirs[:logs]}/build.srpm.log"
    File.open(File.join(@dirs[:tmp], 'srpm.sh'), 'w') { |f| f.puts srpm_cmd }
    sh srpm_cmd

    Dir.chdir cwd
    puts "============================ RPM ============================\n" * 7
    rpm_cmd = "RPM_BUILD_ROOT=#{@dirs[:rpmbuild_buildroot]} "\
      "rpmbuild --define 'debug_package %{nil}' " \
      "-D '_topdir #{@dirs[:rpmbuild]}' " \
      "-D '_rpmdir #{@dirs[:dist]}' -D '_srcrpmdir #{@dirs[:dist]}' " \
      "-D '_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm' " \
      " -v -ba #{spec_path}  " \
      "|& tee #{@dirs[:logs]}/build.rpm.log"

    File.open(File.join(@dirs[:tmp], 'rpm.sh'), 'w') { |f| f.puts rpm_cmd }
    sh rpm_cmd
  end

  def define_rake_tasks
    CLEAN << 'dist'

    Dir['*.spec'].each do |spec|
      cwd = File.expand_path(File.dirname(spec))
      namespace :src do
        task :mkdirs do
          mk_dirs
        end

        desc 'downloads source'
        task download: ['src:mkdirs'] do
          _download(spec, cwd)
        end
      end

      namespace :pkg do
        desc 'builds RPM'
        task rpm: ['src:mkdirs', 'src:download'] do
          build_full_rpm(spec, cwd)
        end
      end
    end
  end
end
