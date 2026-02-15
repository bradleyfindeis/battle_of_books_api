# frozen_string_literal: true

class QuizMatchPayloadBuilder
  def self.build(match)
    current_data = match.current_question_data
    current_question = nil
    if current_data && match.status_in_progress?
      q = QuizQuestion.find_by(id: current_data['quiz_question_id'])
      if q
        choices = match.book_list.book_list_items.order(:position).map { |item| BookListItemSerializer.new(item).as_json }
        steal_ctx = match.current_steal_context
        partial_steal = steal_ctx.is_a?(Hash) && steal_ctx['partial_steal'] && steal_ctx['locked_book_list_item_id'].present?
        current_question = {
          id: q.id,
          question_text: q.question_text,
          correct_book_list_item_id: q.correct_book_list_item_id,
          choices: choices,
          first_responder_id: current_data['first_responder_id']
        }
        if partial_steal
          current_question[:steal_author_only] = true
          current_question[:locked_book_list_item_id] = steal_ctx['locked_book_list_item_id']
        end
      end
    end

    payload = {
      id: match.id,
      status: match.status,
      phase: match.phase,
      challenger_id: match.challenger_id,
      challenger_username: match.challenger.username,
      challenger_avatar: match.challenger.avatar_emoji,
      invited_opponent_id: match.invited_opponent_id,
      invited_opponent_username: match.invited_opponent.username,
      invited_opponent_avatar: match.invited_opponent.avatar_emoji,
      opponent_id: match.opponent_id,
      opponent_username: match.opponent&.username,
      opponent_avatar: match.opponent&.avatar_emoji,
      challenger_score: match.challenger_score,
      opponent_score: match.opponent_score,
      current_question_index: match.current_question_index,
      total_questions: QuizMatch::QUESTIONS_COUNT,
      current_question: current_question
    }
    if match.respond_to?(:phase_entered_at) && match.phase_entered_at.present? &&
       %w[question_show second_responder_can_answer].include?(match.phase)
      payload[:phase_entered_at] = match.phase_entered_at.iso8601(3)
    end
    if match.status_completed? && match.respond_to?(:question_results) && match.question_results.present?
      payload[:question_results] = match.question_results.map do |r|
        first_id = r['first_responder_id']
        first_username = first_id == match.challenger_id ? match.challenger.username : (match.opponent&.id == first_id ? match.opponent&.username : match.invited_opponent.username)
        second_id = first_id == match.challenger_id ? (match.opponent_id || match.invited_opponent_id) : match.challenger_id
        second_username = second_id == match.challenger_id ? match.challenger.username : (match.opponent&.username || match.invited_opponent.username)
        r.slice('question_index', 'quiz_question_id', 'question_text', 'correct_book_title', 'correct_book_author',
                'first_responder_correct', 'second_responder_correct').merge(
          'first_responder_id' => first_id,
          'first_responder_username' => first_username,
          'second_responder_id' => second_id,
          'second_responder_username' => second_username
        )
      end
    end
    payload
  end
end
