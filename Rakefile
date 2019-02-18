require_relative 'lib/simp/rpm/spec_builder'
require_relative 'lib/simp/rpm/spec_builder_config'

config_hash = SIMP::RPM::SpecBuilderConfig.load_config('things_to_build.yaml')
builder = SIMP::RPM::SpecBuilder.new config_hash

builder.define_rake_tasks
