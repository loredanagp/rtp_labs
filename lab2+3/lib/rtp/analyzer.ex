defmodule RTP.Analyzer do
  def calculate_score(tweet) do
    text_words = String.split(tweet["message"]["tweet"]["text"], ~r/[\s.!?:;]+/, trim: true)
    word_count = Enum.count(text_words)

    retweet_count    = tweet["message"]["tweet"]["retweet_count"]
    favorite_count   = tweet["message"]["tweet"]["favorite_count"]
    followers_count  = tweet["message"]["tweet"]["user"]["followers_count"]

    engagement_ratio = if followers_count > 0 do
      (favorite_count + retweet_count) / followers_count
    else
      0
    end

    sentiment_score = case word_count do
      0 -> 0
      _ -> (Enum.map(text_words, &RTP.Sentiments.get(&1)) |> Enum.sum()) / word_count
    end

    { engagement_ratio, sentiment_score }
  end
end
