# frozen_string_literal: true

require "net/http"
require "json"

class QuizChallengeAiService
  OPENAI_CHAT_URL = "https://api.openai.com/v1/chat/completions"
  MODEL = "gpt-4o-mini"

  class Error < StandardError; end

  def self.evaluate(question_text:, official_book:, official_author:, user_book:, user_author:, page_number:, justification:)
    new(
      question_text: question_text,
      official_book: official_book,
      official_author: official_author,
      user_book: user_book,
      user_author: user_author,
      page_number: page_number,
      justification: justification
    ).evaluate
  end

  def initialize(question_text:, official_book:, official_author:, user_book:, user_author:, page_number:, justification:)
    @question_text = question_text
    @official_book = official_book
    @official_author = official_author
    @user_book = user_book
    @user_author = user_author
    @page_number = page_number
    @justification = justification
  end

  def evaluate
    return false if api_key.blank?

    body = build_request_body
    response = send_request(body)
    parse_upheld(response)
  rescue StandardError => e
    Rails.logger.warn("[QuizChallengeAiService] Error: #{e.message}")
    false
  end

  private

  attr_reader :question_text, :official_book, :official_author, :user_book, :user_author, :page_number, :justification

  def api_key
    @api_key ||= ENV["OPENAI_API_KEY"].to_s.strip.presence
  end

  def build_request_body
    {
      model: MODEL,
      messages: [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user",
          content: user_prompt
        }
      ],
      max_tokens: 50,
      temperature: 0
    }
  end

  def system_prompt
    <<~TEXT.strip
      You are judging a "Battle of the Books" quiz challenge. The quiz question asks "In which book does...?" and has an official correct answer (book and author).
      A student is challenging that their answer should also count as correct. They have provided a book, author, page number, and a justification (e.g. quote or description from the book).
      Respond with exactly one word: YES if the student's justification plausibly supports that the answer appears in their chosen book (and optionally at the given page), and their answer is a reasonable correct answer to the question. Otherwise respond NO.
    TEXT
  end

  def user_prompt
    <<~TEXT.strip
      Quiz question: #{question_text}

      Official correct answer: #{official_book} by #{official_author}

      Student's answer: #{user_book} by #{user_author}
      Page: #{page_number.presence || "not given"}

      Student's justification: #{justification}

      Should the student receive the point? YES or NO.
    TEXT
  end

  def send_request(body)
    uri = URI(OPENAI_CHAT_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 30

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{api_key}"
    request.body = body.to_json

    http.request(request)
  end

  def parse_upheld(response)
    return false unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    content = data.dig("choices", 0, "message", "content")
    return false if content.blank?

    content = content.strip.upcase
    content.start_with?("YES")
  end
end
