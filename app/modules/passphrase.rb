class Passphrase
  class << self
    def generate(words: 3, separator: "-")
      my_words = words.times.map { word_list.sample.capitalize }
      ix = rand(my_words.count)
      my_words[ix] = format("%s%i", my_words[ix], rand(9))
      my_words.join(separator)
    end

    def word_list
      File.readlines(Rails.root.join("data/words.txt"), chomp: true)
    end
  end
end
