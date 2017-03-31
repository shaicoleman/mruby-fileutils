##
## FileUtils Test
##

assert("FileUtils") do
  assert_equal Module, FileUtils.class
  assert_equal Module, FileUtils::Verbose.class
  assert_equal Module, FileUtils::NoWrite.class
  assert_equal Module, FileUtils::DryRun.class
end

assert("FileUtils#pwd") do
  assert_equal Dir.pwd, FileUtils.pwd
  assert_equal FileUtils.pwd, FileUtils.getwd
end

assert("FileUtils#cd") do
  FileUtils.cd Dir.tmpdir, {verbose: true}
  assert_equal File.realpath(Dir.tmpdir), FileUtils.pwd
end

assert("FileUtils#uptodate?") do
  old = Tempfile.new 'old'
  oldpath = old.path
  sleep 1
  new = Tempfile.new 'new'
  newpath = new.path

  assert_true FileUtils.uptodate?(newpath, [oldpath])
  assert_false FileUtils.uptodate?(newpath, [oldpath, newpath])
end

assert("FileUtils#mkdir") do
  FileUtils.cd Dir.tmpdir
  suffix = SecureRandom.hex
  test, tmp, data = %w(test tmp data).map {|d| "#{d}_#{suffix}"}

  FileUtils.mkdir test, {verbose: true}
  assert_true Dir.exists? test

  FileUtils.mkdir [tmp, data], {verbose: true}
  assert_true Dir.exists? tmp
  assert_true Dir.exists? data

  [test, tmp, data].each {|d| Dir.delete d}

  FileUtils.mkdir test, {verbose: true, mode: 0700}
  assert_equal "40700", sprintf("%o", File.stat(test).mode)
  Dir.delete test
end

assert("FileUtils#mkdir_p") do
  FileUtils.cd Dir.tmpdir
  path1 = File.join('mkdir_p', SecureRandom.hex.each_char.each_slice(8).map(&:join).join(File::SEPARATOR))

  FileUtils.mkdir_p path1, {verbose: true}
  assert_true Dir.exists? path1
  Dir.delete path1

  FileUtils.mkdir_p path1, {verbose: true, mode: 0700}
  assert_equal "40700", sprintf("%o", File.stat(path1).mode)
  Dir.delete path1

  path2 = File.join('mkdir_p', SecureRandom.hex.each_char.each_slice(8).map(&:join).join(File::SEPARATOR))
  FileUtils.mkdir_p [path1, path2], {verbose: true}
  assert_true Dir.exists? path1
  assert_true Dir.exists? path2
end

assert("FileUtils#rmdir") do
  path = "rmdir_#{SecureRandom.hex}"

  FileUtils.mkdir path, {verbose: true}
  assert_true Dir.exists? path

  FileUtils.rmdir path, {verbose: true}
  assert_false Dir.exists? path

  path_depth = File.join(path, SecureRandom.hex.each_char.each_slice(8).map(&:join).join(File::SEPARATOR))
  FileUtils.mkdir_p path_depth, {verbose: true}
  FileUtils.rmdir path_depth, {verbose: true, parents: true}

  assert_false Dir.exist? path
end

assert 'FileUtils#remove_file' do
  path = File.join Dir.tmpdir, "rm_#{SecureRandom.hex}"
  File.open path, 'w' do |f|
    f.write 'test'
  end
  assert_true File.exists? path

  FileUtils.remove_file path, verbose: true
  assert_false File.exists? path

  assert_false File.exists? path
  FileUtils.remove_file path, verbose: true, force: true
  assert_false File.exists? path

  assert_raise RuntimeError do
    FileUtils.remove_file path, verbose: true
  end
end

assert 'FileUtils#rm_r' do
  path = File.join Dir.tmpdir, "rm_r_#{SecureRandom.hex}"

  FileUtils.mkdir path
  File.open File.join(path, 'test'), 'w' do |f|
    f.write 'test'
  end
  assert_true Dir.exists? path

  FileUtils.rm_r path, verbose: true
  assert_false Dir.exists? path

  File.open path, 'w' do |f|
    f.write 'test'
  end
  assert_true File.exists? path
  FileUtils.rm_r path, verbose: true
  assert_false File.exists? path

  assert_false File.exists? path
  FileUtils.rm_r path, verbose: true, force: true
  assert_false File.exists? path

  assert_raise RuntimeError do
    FileUtils.rm_r path, verbose: true
  end
end

assert 'FileUtils#rm_rf' do
  path = File.join Dir.tmpdir, "rm_r_#{SecureRandom.hex}"

  FileUtils.mkdir path
  File.open File.join(path, 'test'), 'w' do |f|
    f.write 'test'
  end
  assert_true Dir.exists? path

  FileUtils.rm_rf path, verbose: true
  assert_false Dir.exists? path
  FileUtils.rm_rf path, verbose: true

  assert_raise RuntimeError do
    FileUtils.rm_r path, verbose: true, force: false
  end
end

assert 'FileUtils#copy_file' do
  src = File.join Dir.tmpdir, "copy_file_#{SecureRandom.hex}"
  dst = File.join Dir.tmpdir, "copy_file_#{SecureRandom.hex}"

  File.open src, 'w' do |f|
    f.write 'test'
  end

  FileUtils.copy_file src, dst, verbose: true
  File.open dst do |f|
    assert_equal 'test', f.read
  end

  FileUtils.remove_file src
  FileUtils.remove_file dst
end

assert 'FileUtils#cp' do
  src1 = File.join Dir.tmpdir, "cp_#{SecureRandom.hex}"
  src2 = File.join Dir.tmpdir, "cp_#{SecureRandom.hex}"
  dst = File.join Dir.tmpdir, "cp_#{SecureRandom.hex}"

  FileUtils.mkdir dst

  File.open src1, 'w' do |f|
    f.write 'test1'
  end
  File.open src2, 'w' do |f|
    f.write 'test2'
  end

  FileUtils.cp src1, dst, verbose: true
  assert_true File.exists? File.join(dst, File.basename(src1))
  File.open File.join(dst, File.basename(src1)) do |f|
    assert_equal 'test1', f.read
  end
  FileUtils.remove_file File.join(dst, File.basename(src1))

  FileUtils.cp [src1, src2], dst, verbose: true
  assert_true File.exists? File.join(dst, File.basename(src1))
  assert_true File.exists? File.join(dst, File.basename(src2))

  FileUtils.remove_file src1
  FileUtils.remove_file src2
  FileUtils.rm_r dst
end
