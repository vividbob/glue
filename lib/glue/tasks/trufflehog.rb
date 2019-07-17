require 'glue/tasks/base_task'
require 'glue/util'
require 'httparty'

# Runs the TruffleHog scanner. See https://github.com/dxa4481/truffleHog for details.
class Glue::Trufflehog < Glue::BaseTask
  Glue::Tasks.add self
  include Glue::Util

  ISSUE_SEVERITY = 3 

  def initialize(trigger, tracker)
    super(trigger, tracker)
    @name = "Trufflehog"
    @description = "Runs Trufflehog check"
    @stage = :code
    @labels << "code" << "java" << ".net"

    @trufflehog_path = '/home/glue/tools/truffleHog/truffleHog/truffleHog.py'
  end

  def run
    Glue.notify "#{@name}"
    @result = runsystem(true, '/usr/bin/env', 'python', @trufflehog_path, '--json', '--regex', '--entropy=False', '--repo_path', @trigger.path, 'dummyRepoURL')
  end

  def analyze
    begin
      # Glue.debug "Parsing results..."
      # puts @result
      get_warnings
    rescue Exception => e
      Glue.notify "Problem running Trufflehog ... skipped."
      Glue.notify e.message
      raise e
    end
  end

  def supported?
    if runsystem(false, '/usr/bin/env', 'python', @trufflehog_path, '-h').empty?
      Glue.notify "Check that TruffleHog is installed at #{@trufflehog_path}."
      return false
    end

    true
  end

  private

  def get_warnings
    (@result.lines.map(&:chomp)).each do |issue_json|
      issue = JSON::parse(issue_json)
      detail = "Found #{issue['reason']} in #{issue['path']} as present in commit hash #{issue['commitHash']} with commit description '#{issue['commit'].chomp}' on branch #{issue['branch']} from #{issue['date']}. Strings at issue: #{issue['stringsFound'].join(', ')}"
      fingerprint = "Trufflehog|#{issue['reason']}"
      self.report "Possible password or other secret in source code.", detail, issue['reason'], ISSUE_SEVERITY, fingerprint
    end
  end
end
