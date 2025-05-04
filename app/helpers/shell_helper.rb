module ShellHelper
  def sh(command, title: nil, show_output: false, raise_error: true)
    title ||= command
    logger.info("#{title}: #{command}")
    if raise_error
      result, out_data, err_data = 0, "", ""
      Open3.popen3(command) do |_, out, err, thr|
         out_data, err_data, result = out.read, err.read, thr.value
      end
    else
      `#{command}`
      result = $?
    end

    log = "#{title}, result=#{result.to_i}"
    logger.info(log)
    output = "STDOUT:\n#{out_data}\n\nSTDERR:\n#{err_data}"
    if raise_error && result != 0
      data = "#{log}\n\n#{output}\n\n"
      logger.error("STDERR:\n#{err_data}\n")
      raise IOError, "Error executing command (exit=#{result}): #{data}"
    elsif show_output
      puts(output)
    end

    result
  end
end
