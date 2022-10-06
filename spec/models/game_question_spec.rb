require 'rails_helper'

RSpec.describe GameQuestion, type: :model do
  let(:game_question) do
    FactoryGirl.create(:game_question, a: 2, b: 1, c: 4, d: 3)
  end

  context 'game status' do
    it 'correct .variants' do
      expect(game_question.variants).to eq(
        'a' => game_question.question.answer2,
        'b' => game_question.question.answer1,
        'c' => game_question.question.answer4,
        'd' => game_question.question.answer3
      )
    end

    it 'correct .answer_correct?' do
      expect(game_question.answer_correct?('b')).to be_truthy
    end

    it 'correct .level & .text delegates' do
      expect(game_question.text).to eq(game_question.question.text)
      expect(game_question.level).to eq(game_question.question.level)
    end
  end

  describe '#correct_answer_key' do
    it 'returns correctly' do
      expect(game_question.correct_answer_key).to eq('b')
    end
  end

  context 'user helpers' do
    it 'correct audience_help' do
      expect(game_question.help_hash).not_to include(:audience_help)

      game_question.add_audience_help

      expect(game_question.help_hash).to include(:audience_help)

      ah = game_question.help_hash[:audience_help]
      expect(ah.keys).to contain_exactly('a', 'b', 'c', 'd')
    end
  end

  it 'correct .help_hash' do
    expect(game_question.help_hash).to eq({})

    game_question.help_hash[:some_key1] = 'blabla1'
    game_question.help_hash['some_key2'] = 'blabla2'

    expect(game_question.save).to be_truthy

    gq = GameQuestion.find(game_question.id)

    expect(gq.help_hash).to eq({some_key1: 'blabla1', 'some_key2' => 'blabla2'})
  end

  describe '.add_audience_help' do
    before do
      game_question.add_audience_help
    end

    it 'has a help_hash' do
      expect(game_question.help_hash[:audience_help]).to be
    end

    it 'contains variants' do
      expect(game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
    end
  end

  context '.add_fifty_fifty' do
    let(:values) { game_question.help_hash[:fifty_fifty] }

    before do
      game_question.add_fifty_fifty
    end

    it 'has a help_hash' do
      expect(game_question.help_hash[:fifty_fifty]).to be
    end

    it 'Remaining variants includes correct variant' do
      expect(values).to include(game_question.correct_answer_key)
    end

    it 'Only 2 variants left' do
      expect(values.size).to eq 2
    end
  end

  describe '.add_friend_call' do
    let(:value) { game_question.help_hash[:friend_call] }

    before do
      game_question.add_friend_call
    end

    it 'has a help_hash' do
      expect(game_question.help_hash[:friend_call]).to be
    end

    it 'contains some of variant' do
      expect(value).to match(/считает, что это вариант [ABCD]/)
    end
  end
end
