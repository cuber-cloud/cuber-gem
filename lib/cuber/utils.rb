module Cuber::Utils

  def kubectl *args
    cmd = ['kubectl', '--kubeconfig', @options[:kubeconfig], '-n', @options[:app]] + args
    system(*cmd) || abort("Cuber: \"#{cmd.shelljoin}\" failed")
  end

  def kubeget type, name = nil, *args
    cmd = ['kubectl', 'get', type, name, '-o', 'json', '--kubeconfig', @options[:kubeconfig], '-n', @options[:app], *args].compact
    out, status = Open3.capture2 *cmd
    abort "Cuber: \"#{cmd.shelljoin}\" failed" unless status.success?
    out.empty? ? nil : JSON.parse(out)
  end

  def render template, target_file = nil
    template = File.join __dir__, 'templates', "#{template}.erb"
    renderer = ERB.new File.read(template), trim_mode: '-'
    content = renderer.result binding
    return content unless target_file
    FileUtils.mkdir_p File.dirname target_file
    File.write target_file, content
  end
  
end
