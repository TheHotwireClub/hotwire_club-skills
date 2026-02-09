#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'front_matter_parser'
  gem 'psych', '>= 5.0'
end

require 'yaml'
require 'fileutils'
require 'pathname'
require 'date'
require 'front_matter_parser'

# Configure Psych to allow Date class (required for Psych 5.x)
if defined?(Psych) && Psych::VERSION >= "5.0" && defined?(Psych::ClassLoader::Restricted)
  Psych::ClassLoader::Restricted.class_eval do
    alias_method :original_find, :find
    def find(name)
      case name
      when "Date"
        Date
      when "Time"
        Time
      when "DateTime"
        DateTime
      else
        original_find(name)
      end
    end
  end
end

# Script to sync articles from corpus to references/ directory
class SyncReferences
  def initialize(config_path: 'config/supertopic-mapping.yml')
    @config = YAML.load_file(config_path)
    @corpus_path = Pathname.new(@config['corpus_path'])
    @skills = @config['skills']
  end

  def run
    puts "Starting sync from #{@corpus_path} to skill references/\n\n"
    
    @skills.each do |skill_key, skill_data|
      sync_skill(skill_key, skill_data)
    end
    
    puts "\n✅ Sync complete!"
  end

  private

  def sync_skill(skill_key, skill_data)
    skill_dir_name = "hwc-#{skill_key}"
    puts "Syncing #{skill_dir_name} (#{skill_data['title']})..."
    
    # Create references subdirectory inside the skill directory
    skill_ref_dir = Pathname.new("skills/#{skill_dir_name}/references")
    FileUtils.mkdir_p(skill_ref_dir)

    # Copy each article to the references directory
    skill_data['articles'].each do |article_filename|
      source_file = @corpus_path / article_filename
      dest_file = skill_ref_dir / article_filename

      if source_file.exist?
        FileUtils.cp(source_file, dest_file)
        puts "  ✓ Copied #{article_filename}"
      else
        puts "  ✗ Warning: #{article_filename} not found in corpus"
      end
    end

    # Create index file
    create_index_file(skill_ref_dir, skill_data)
    puts ""
  end

  def create_index_file(skill_ref_dir, skill_data)
    index_path = skill_ref_dir / 'INDEX.md'
    
    content = <<~MD
      # #{skill_data['title']}
      
      #{skill_data['description']}
      
      ## Hotwire Focus
      
      #{skill_data['hotwire_focus'].map { |f| "- #{f}" }.join("\n")}
      
      ## Articles in this skill
      
    MD

    skill_data['articles'].each do |article_filename|
      article_path = skill_ref_dir / article_filename
      
      if article_path.exist?
        begin
          parsed = FrontMatterParser::Parser.parse_file(article_path)
          title = parsed.front_matter['title'] || article_filename
          description = parsed.front_matter['description'] || ''
          
          content += "- [#{title}](#{article_filename})"
          content += " - #{description}" unless description.empty?
          content += "\n"
        rescue => e
          puts "  ⚠ Warning: Could not parse #{article_filename}: #{e.message}"
          content += "- [#{article_filename}](#{article_filename})\n"
        end
      end
    end

    File.write(index_path, content)
    puts "  ✓ Created INDEX.md"
  end
end

# Run the sync
if __FILE__ == $0
  SyncReferences.new.run
end
