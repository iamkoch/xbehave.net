require 'albacore'

version_suffix1 = ENV["VERSION_SUFFIX1"] || ""
version_suffix2 = ENV["VERSION_SUFFIX2"] || "-alpha"
build_number    = ENV["BUILD_NUMBER"]    || "000000"
build_number_suffix1 = version_suffix1 == "" ? "" : "-build" + build_number
build_number_suffix2 = version_suffix2 == "" ? "" : "-build" + build_number
version1 = IO.read("src/VersionInfo.1.cs").split(/AssemblyInformationalVersion\("/, 2)[1].split(/"/).first + version_suffix1 + build_number_suffix1
version2 = IO.read("src/VersionInfo.2.cs").split(/AssemblyInformationalVersion\("/, 2)[1].split(/"/).first + version_suffix2 + build_number_suffix2

$msbuild_command = "C:/Program Files (x86)/MSBuild/12.0/Bin/MSBuild.exe"
$xunit_command = "src/packages/xunit.runners.2.0.0-rc1-build2826/tools/xunit.console.exe"
nuget_command = "src/packages/NuGet.CommandLine.2.8.3/tools/NuGet.exe"
$solution = "src/Xbehave.sln"
output = "artifacts/output"
logs = "artifacts/logs"

component_tests = [
  "src/test/Xbehave.Sdk.Test.Component.Net35/bin/Release/Xbehave.Sdk.Test.Component.Net35.dll",
  "src/test/Xbehave.Test.Component.Net35/bin/Release/Xbehave.Test.Component.Net35.dll",
  "src/test/Xbehave.Sdk.Test.Component.Net40/bin/Release/Xbehave.Sdk.Test.Component.Net40.dll",
  "src/test/Xbehave.Test.Component.Net40/bin/Release/Xbehave.Test.Component.Net40.dll",
]

acceptance_tests = [
  "src/test/Xbehave.Test.Acceptance.Net35/bin/Release/Xbehave.Test.Acceptance.Net35.dll",
  "src/test/Xbehave.Test.Acceptance.Net40/bin/Release/Xbehave.Test.Acceptance.Net40.dll",
  "src/test/Xbehave.Test.Acceptance.Net45/bin/Release/Xbehave.Test.Acceptance.Net45.dll",
  "src/test/Xbehave.2.Test.Acceptance.Net45/bin/Release/Xbehave.Test.Acceptance.Net45.dll",
]

nuspecs = [
  { :file => "src/Xbehave.nuspec", :version => version1 },
  { :file => "src/Xbehave.2.nuspec", :version => version2 }
]

Albacore.configure do |config|
  config.log_level = :verbose
end

desc "Execute default tasks"
task :default => [:component, :accept, :pack]

desc "Restore NuGet packages"
exec :restore do |cmd|
  cmd.command = nuget_command
  cmd.parameters "restore #{$solution}"
end

directory logs

desc "Clean solution"
task :clean => [logs] do
  run_msbuild "Clean"
end

desc "Build solution"
task :build => [:clean, :restore, logs] do
  run_msbuild "Build"
end

desc "Run component tests"
task :component => [:build] do
  run_tests component_tests
end

desc "Run acceptance tests"
task :accept => [:build] do
  run_tests acceptance_tests
end

directory output

desc "Create the nuget packages"
task :pack => [:build, output] do
  nuspecs.each do |nuspec|
    cmd = Exec.new
    cmd.command = nuget_command
    cmd.parameters "pack " + nuspec[:file] + " -Version " + nuspec[:version] + " -OutputDirectory " + output + " -NoPackageAnalysis"
    cmd.execute
  end
end

def run_msbuild(target)
  cmd = Exec.new
  cmd.command = $msbuild_command
  cmd.parameters "#{$solution} /target:#{target} /p:configuration=Release /nr:false /verbosity:minimal /nologo /fl /flp:LogFile=artifacts/logs/#{target}.log;Verbosity=Detailed;PerformanceSummary"
  cmd.execute
end

def run_tests(tests)
  tests.each do |test|
    xunit = XUnitTestRunner.new
    xunit.command = $xunit_command
    xunit.assembly = test
    xunit.options "-html", File.expand_path(test + ".TestResults.html"), "-xml", File.expand_path(test + ".TestResults.xml")
    xunit.execute  
  end
end
