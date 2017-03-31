module FileUtils
  def pwd
    Dir.pwd
  end
  module_function :pwd

  alias getwd pwd
  module_function :getwd

  def cd(dir, options = {}, &block)
    _output_message "cd #{dir}" if options[:verbose]
    Dir.chdir(dir, &block)
    _output_message 'cd -' if options[:verbose] and block
  end
  module_function :cd

  alias chdir cd
  module_function :chdir

  def uptodate?(new, old_list)
    return false unless File.exist?(new)
    new_time = File.stat(new).mtime
    old_list.each do |old|
      if File.exist?(old)
        return false unless new_time > File.stat(old).mtime
      end
    end
    true
  end
  module_function :uptodate?

  def mkdir(list, options = {})
    list = [list].flatten.map{|path| File.path(path)}
    _output_message "mkdir #{options[:mode] ? ('-m %03o ' % options[:mode]) : ''}#{list.join ' '}" if options[:verbose]
    return if options[:noop]

    list.each do |dir|
      if options[:mode]
        Dir.mkdir dir, options[:mode]
      else
        Dir.mkdir dir
      end
    end
  end
  module_function :mkdir

  def mkdir_p(list, options = {})
    list = [list].flatten.map{|path| File.path(path)}
    _output_message "mkdir -p #{options[:mode] ? ('-m %03o ' % options[:mode]) : ''}#{list.join ' '}" if options[:verbose]
    return *list if options[:noop]

    list.map {|path| _remove_trailing_slash(path)}.each do |path|
      begin
        if options[:mode]
          Dir.mkdir dir, options[:mode]
        else
          Dir.mkdir dir
        end
        next
      rescue
        next if Dir.exists? path
      end

      stack = []
      until path == stack.last
        stack.push path
        path = File.dirname(path)
      end
      stack.reverse_each do |dir|
        begin
          if options[:mode]
            Dir.mkdir dir, options[:mode]
          else
            Dir.mkdir dir
          end
        rescue
          raise unless Dir.exists? dir
        end
      end
    end

    return *list
  end
  module_function :mkdir_p

  alias mkpath    mkdir_p
  alias makedirs  mkdir_p
  module_function :mkpath
  module_function :makedirs

  def rmdir(list, options = {})
    list = [list].flatten.map{|path| File.path(path)}
    parents = options[:parents]
    _output_message "rmdir #{parents ? '-p ' : ''}#{list.join ' '}" if options[:verbose]
    return if options[:noop]
    list.each do |dir|
      Dir.rmdir(dir = _remove_trailing_slash(dir)) if Dir.exists? dir
      if parents
        until (parent = File.dirname(dir)) == '.' or parent == dir
          dir = parent
          Dir.rmdir(dir) if Dir.exists? dir
        end
      end
    end
  end
  module_function :rmdir

  def remove_file(path, opts = {})
    File.unlink path
  rescue
    raise unless opts[:force]
  end

  def rm_f list, opts = {}
    list = [list] unless list.kind_of? Array
    opts[:force] = true if opts[:force].nil?

    _output_message "rm#{opts[:force] ? ' -f' : ''} #{list.join ' '}" if opts[:verbose]
    return if opts[:noop]

    list.each do |p|
      remove_file p, opts
    end
  end

  def rm_r list, opts = {}
    list = [list] unless list.kind_of? Array

    _output_message "rm -r#{opts[:force] ? 'f' : ''} #{list.join ' '}" if opts[:verbose]
    return if opts[:noop]

    list.each do |path|
      if File.directory? path
        Dir.entries(path).each do |ent|
          next if ent == '.' || ent == '..'
          ent_path = File.join path, ent
          if File.directory? ent_path
            rm_r ent_path, opts
          else
            remove_file ent_path, opts
          end
        end
        rmdir path, opts
      else
        remove_file path, opts
      end
    end
  end

  def rm_rf list, opts = {}
    opts[:force] = true if opts[:force].nil?
    rm_r list, opts
  end

  module_function :remove_file, :rm_f, :rm_r, :rm_rf

  def copy_file src, dst, preserve = false
    File.open src, 'rb' do |s|
      File.open dst, 'wb', s.stat.mode do |d|
        d.write s.read
      end
    end

    # TODO:
    # copy_metadata src, dst if preserve
  end

  def cp src, dst, opts = {}
    _output_message "cp#{opts[:preserve] ? ' -p' : ''} #{[src,dst].flatten.join ' '}" if opts[:verbose]
    return if opts[:noop]

    src = [src] unless src.is_a? Array

    src.each do |s|
      if File.directory? dst
        copy_file s, File.join(dst, File.basename(s)), opts[:preserve]
      else
        copy_file s, dst, opts[:preserve]
      end
    end
  end

  module_function :copy_file, :cp

  def self._output_message(msg)
    $stderr.puts msg
  end

  def self._remove_trailing_slash(dir)
    dir == '/' ? dir : dir.chomp(?/)
  end
end
