# (c) goodprogrammer.ru

require 'rails_helper'

# Тестовый сценарий для модели Вопрос
#
# Вопрос не содержит функционала (это просто хранилище данных), поэтому все
# тесты сводятся только к проверке наличия нужных валидаций.
#
# Обратите внимание, что работу самих валидаций не надо тестировать (это работа
# авторов rails). Смысл именно в проверке _наличия_ у модели конкретных
# валидаций.
RSpec.describe Question, type: :model do

  let(:game) { assigns(:game) }

  before do
    sign_in user
  end
  let(:game_question) do
    FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)
  end

  context 'validations check' do
    it { should validate_presence_of :level }
    it { should validate_presence_of :text }
    it { should validate_inclusion_of(:level).in_range(0..14) }

    it { should_not allow_value(500).for(:level) }
    it { should allow_value(14).for(:level) }

    subject { Question.new(text: 'some', level: 0, answer1: '1', answer2: '1', answer3: '1', answer4: '1') }

    it { should validate_uniqueness_of :text }
  end

  describe '#add_audience_help' do
    before do
      sign_in user
      put :help, id: game_w_questions.id, help_type: :audience_help
      game = assigns(:game)
    end

    it 'contains variants' do
      expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
    end
  end

  context '#add_fifty_fifty' do
    let(:values) { game_question.help_hash[:fifty_fifty] }

    before do
      put :help, id: game_w_questions.id, help_type: :fifty_fifty
      game_question.add_fifty_fifty
    end

    it 'Remaining variants includes correct variant' do
      expect(values).to include(game_question.correct_answer_key)
    end

    it 'Only 2 variants left' do
      expect(values.size).to eq 2
    end
  end

  describe '#add_friend_call' do
    let(:value) { game_question.help_hash[:friend_call] }

    before do
      put :help, id: game_w_questions.id, help_type: :friend_call
      game_question.add_friend_call
    end

    it 'contains some of variant' do
      expect(value).to match(/[ABCD]/)
    end
  end
end
