require 'open3'
require 'pathname'
require 'digest'

module Glue::Util

  def runsystem(report, *splat)
    Open3.popen3(*splat) do |stdin, stdout, stderr, wait_thr|

      out_reader = Thread.new { stdout.read }
      if $logfile and report
        while line = stderr.gets do
          $logfile.puts line
        end
      else
        err_reader = Thread.new { stderr.read }
      end
      output = out_reader.value.chomp
      if report and output.match("usage:")
        raise SyntaxError, "Invalid command syntax.\n\n#{output}"
      end
      return output
    end
  end

  def fingerprint text
    Digest::SHA2.new(256).update(text).to_s
  end

  def strip_archive_path path, delimeter
    path.split(delimeter).last.split('/')[1..-1].join('/')
  end

  def relative_path path, pwd
    pathname = Pathname.new(path)
    return path if pathname.relative?
    pathname.relative_path_from(Pathname.new pwd)
  end
end
