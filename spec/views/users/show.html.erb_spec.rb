require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:game_user) { FactoryGirl.create(:user, name: 'Max') }
  let(:another_user) { FactoryGirl.create(:user, name: 'Not_Max') }

  before(:each) { assign(:user, game_user) }

  it "show game_user name" do
    render
    expect(rendered).to match game_user.name
  end

  context 'show link for change password' do
    it 'for game_user' do
      sign_in game_user
      render
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'for another_user' do
      sign_in another_user
      render
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end

  context 'show game elements' do
    before(:each) do
      assign(:games, [FactoryGirl.build_stubbed(:game, id: 1, prize: 5000)])
      render
    end

    it "id" do
      expect(rendered).to match('1')
    end

    it "prize" do
      expect(rendered).to match('5 000')
    end

    it "50/50" do
      expect(rendered).to match('50/50')
    end

    it "status" do
      expect(rendered).to match('в процессе')
    end
  end
end
