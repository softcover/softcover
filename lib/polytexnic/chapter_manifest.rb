class Polytexnic::ChapterManifest

  YAML_PATH = "chapters.yml"
  MD_PATH = "Book.txt"

  attr_accessor :chapters

  def initialize(opts={})
    @chapters = case
    when md? then read_from_md
    when polytex? then read_from_yml
    else
      fail
    end

    verify_paths! if opts[:verify_paths]
  end

  def md?
    File.exists?(MD_PATH)
  end

  def polytex?
    File.exists?(YAML_PATH)
  end

  def chapter_file_paths
    @chapters.map do |chapter_path|
      file_path = case
      when md? then chapter_path
      when polytex? then "chapters/#{chapter_path}.tex"
      end

      yield file_path if block_given?

      file_path
    end
  end

  def slugs
    @chapters.map { |c| File.basename c, ".*" }
  end

  private
    def read_from_yml
      YAML.load_file YAML_PATH
    end

    def read_from_md
      return false unless 

      f = File.open(MD_PATH) 
      chapters = f.readlines.map { |path| path.gsub /\n/,'' }
      f.close
      chapters
    end

    def fail
      # TODO: raise error with instructions on adding a chapter manifest
      raise "No chapter manifest!"
    end

    def verify_paths!
      chapter_file_paths do |chapter_path|
        unless File.exists?(chapter_path)
          raise "Chapter file in manifest not found" 
        end
      end
    end
end