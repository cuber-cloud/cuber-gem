module Cuber::Commands
  class Info
    include Cuber::Utils

    def initialize options
      @options = options
      @namespace = nil
    end

    def execute
      set_namespace
      print_app_version
      print_public_ip
      print_env
      print_migration
      print_proc
      print_cron
      print_pods
    end

    private

    def set_namespace
      @namespace = kubeget 'namespace', @options[:app]
      abort 'Cuber: app not found' if @namespace.dig('metadata', 'labels', 'app.kubernetes.io/managed-by') != 'cuber'
    end

    def print_section title
      puts
      puts "\e[34m=== #{title}\e[0m"
    end

    def print_app_version
      print_section 'App'
      puts "#{@namespace['metadata']['labels']['app.kubernetes.io/name']}"
      puts "version #{@namespace['metadata']['labels']['app.kubernetes.io/version']}"
    end

    def print_public_ip
      print_section 'Public IP'
      if @namespace['metadata']['annotations']['ingress'] == 'true'
        json = kubeget 'ingress', 'web-ingress'
      else
        json = kubeget 'service', 'load-balancer'
      end
      ip = json.dig 'status', 'loadBalancer', 'ingress', 0, 'ip'
      if ip
        puts "#{ip}"
      else
        puts "None detected"
      end
    end

    def print_env
      print_section 'Env'
      json = kubeget 'configmap', 'env'
      json['data']&.each do |key, value|
        puts "#{key}=#{value}"
      end
      json = kubeget 'secrets', 'app-secrets'
      json['data']&.each do |key, value|
        puts "#{key}=#{Base64.decode64(value)[0...5] + '***'}"
      end
    end

    def print_migration
      print_section 'Migration'
      migration = "migrate-#{@namespace['metadata']['labels']['app.kubernetes.io/instance']}"
      json = kubeget 'job', migration, '--ignore-not-found'
      if json
        migration_command = json['spec']['template']['spec']['containers'][0]['command'].shelljoin
        migration_status = json['status']['succeeded'].to_i.zero? ? 'Pending' : 'Completed'
        puts "migrate: #{migration_command} (#{migration_status})"
      else
        puts "None detected"
      end
    end

    def print_proc
      print_section 'Proc'
      json = kubeget 'deployments'
      json['items'].each do |proc|
        name = proc['metadata']['name']
        command = proc['spec']['template']['spec']['containers'][0]['command'].shelljoin
        available = proc['status']['availableReplicas'].to_i
        updated = proc['status']['updatedReplicas'].to_i
        replicas = proc['status']['replicas'].to_i
        scale = proc['spec']['replicas'].to_i
        puts "#{name}: #{command} (#{available}/#{scale}) #{'OUT-OF-DATE' if replicas - updated > 0}"
      end
    end

    def print_cron
      print_section 'Cron'
      json = kubeget 'cronjobs'
      json['items'].each do |cron|
        name = cron['metadata']['name']
        schedule = cron['spec']['schedule']
        command = cron['spec']['jobTemplate']['spec']['template']['spec']['containers'][0]['command'].shelljoin
        last = cron['status']['lastScheduleTime']
        puts "#{name}: #{schedule} #{command} #{'(' + time_ago_in_words(last) + ')' if last}"
      end
    end

    def print_pods
      print_section 'Pods'
      json = kubeget 'pods'
      json['items'].each do |pod|
        name = pod['metadata']['name']
        created_at = pod['metadata']['creationTimestamp']
        pod_status = pod['status']['phase']
        container_ready = pod.dig('status', 'containerStatuses', 0, 'ready')
        container_status = pod.dig('status', 'containerStatuses', 0, 'state')&.values&.first&.[]('reason')
        if pod_status == 'Succeeded' || (pod_status == 'Running' && container_ready)
          puts "#{name}: \e[32m#{container_status || pod_status}\e[0m (#{time_ago_in_words created_at})"
        else
          puts "#{name}: \e[31m#{container_status || pod_status}\e[0m (#{time_ago_in_words created_at})"
        end
      end
    end

    def time_ago_in_words time
      time = Time.parse time unless time.is_a? Time
      seconds = (Time.now - time).round
      case
      when seconds < 60 then "#{seconds}s"
      when seconds < 60*60 then "#{(seconds / 60)}m"
      when seconds < 60*60*24 then "#{(seconds / 60 / 60)}h"
      else "#{(seconds / 60 / 60 / 24)}d"
      end
    end

  end
end
