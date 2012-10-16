module Polytexnic::ChapterManifest
  extend self

  YAML_PATH = "chapters.yml"

  def read
    if File.exists?(YAML_PATH)
      read_from_yml
    else
      read_from_leanpub
    end
  end

  def read_from_yml
    YAML.load_file YAML_PATH
  end

  def read_from_leanpub
    raise "not implemented"
  end
end