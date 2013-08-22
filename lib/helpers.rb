require 'open3'

module Helpers
  module_function

  def sh(command, title = "", write_error = true)
    puts(log = "#{Time.now}: #{title}: #{command}")
    if write_error
      result, out_data, err_data = 0, "", ""
      Open3.popen3(command) do |_, out, err, thr|
         out_data, err_data, result = out.read, err.read, thr.value
      end
    else
      `#{command}`
      result = $?
    end
    puts(log = "#{Time.now}: #{title}, result=#{result.to_i}")
    if write_error && result != 0
      data = "#{log}\n\nSTDOUT:\n#{out_data}\n\nSTDERR:\n#{err_data}\n\n"
      write_error_file(data)
    end
    result
  end
end