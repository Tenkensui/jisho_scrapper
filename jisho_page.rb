#JishoScrapper
#Copyright (C) 2016 Marc Carné
#
#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program.  If inot, see <http://www.gnu.org/licenses/>.

require 'rubygems'
require 'nokogiri'
require 'uri'
require 'open-uri'

require_relative 'word'
require_relative 'character'
require_relative 'meaning'

class JishoPage

  JISHO_URL = 'http://jisho.org/search/'

  BANNED_TAGS = [ 'Wikipedia definition',
                  'Other forms',
                  'Notes' ]

  # Loads JISHO result page with a given search_term and a given page (defaulting to 1)
  def search(search_term, page=1)
    url = JISHO_URL + search_term + "?page=#{page}"
    encoded_url = URI.escape(url)
    @doc = Nokogiri::HTML(open(encoded_url))
    return @doc
  end

  # Gets the word count once a search has been done
  def get_word_count
    if nil == @doc
      return 0
    end
    result = @doc.css("span[class='result_count']")
    result = result[0].text.gsub(/[^\d]/, '')
    return result.to_i
  end

  # Gets the array of Words from the current search
  def get_words
    if nil == @doc
      return nil
    end
    words = Array.new

    results = @doc.css("div[class='concept_light clearfix']")
    results.each do |result|
      word = Word.new
      word.full_word = get_word_text(result)
      word.characters = get_characters(result)
      word.furigana = get_furigana(result) 
      word.meanings = get_meanings(result)

      words.push( word )
    end

    return results
  end

  def get_word_text(word_element)       
    text = word_element.css("span[class=text]")
    return text.text.strip
  end

  def get_characters(word_element)
    characters = Array.new
    text = word_element.css("span[class=text]").text.strip
    # All characters in span are kana
    nonkanji = word_element.css("span[class=text]/span").text.strip
    text.split(//).each do |char|
      character = Character.new
      character.char = char
      character.is_kanji = !(nonkanji.include? char)
      characters.push(character)
    end
    return characters
  end

  def get_furigana(word_element)
    furiganas = Array.new
    furigana_spans = word_element.css("div.concept_light-representation/span.furigana/span")
    furigana_spans.each do |kana|
      furiganas.push( kana.text.strip )
    end
  end

  def get_meanings(word_element)
    meanings = Array.new
    meaning_container_divs = word_element.css("div.meanings-wrapper/div")
    # Structure since here is one div.meaning-tag and one div.meaning-wrapper
    tag = ''
    meaning_container_divs.each do |div|
      cls = div.attribute('class').text.strip
      if cls.eql? "meaning-tags"
        tag = div.text.strip
      elsif not BANNED_TAGS.include? tag 
        meaning = Meaning.new
        meaning.tag = tag
        meaning.text = div.css("div.meaning-definition/span.meaning-meaning").text.strip
        
        puts meaning.tag + " - " + meaning.text
        meanings.push(meaning)
      end
    end
  end 
end

jisho = JishoPage.new
jisho.search('#jlpt-n5 #words', 2)
#jisho.search('onakagasuku')

#puts jisho.get_word_count
jisho.get_words
