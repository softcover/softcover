require 'spec_helper'

describe User do
  context 'accessing purchased books' do
    before do
      @books = (0..2).map{|i| Fabricate :book, title: "Book #{i}" }

      @option_1_name = 'PDF Only'
      @option_2_name = 'Screencasts Only'
      @option_3_name = 'Both PDF & Screencasts'

      @medium_1_name = 'PDF'
      @medium_2_name = 'Screencasts'

      3.times do |i|
        book = @books[i]

        medium_1 = Fabricate :book_medium, name: @medium_1_name, book: book
        medium_2 = Fabricate :book_medium, name: @medium_2_name, book: book

        option_1 = Fabricate :book_option, book: book, name: @option_1_name, price_in_dollars: 25
        option_2 = Fabricate :book_option, book: book, name: @option_2_name, price_in_dollars: 50
        option_3 = Fabricate :book_option, book: book, name: @option_3_name, price_in_dollars: 50

        option_1.media << medium_1
        option_2.media << medium_2
        option_3.media << [medium_1, medium_2]
      end
    end

    context 'when book option with one medium has been purchased' do
      before do
        @user = Fabricate :user
        Fabricate :purchase, book_option: @books[0].options.find_by_name(@option_1_name), user: @user
      end

      it 'should give user access to book and medium' do
        @user.owned_books.should include @books[0]
        @user.owned_media.should include @books[0].media.find_by_name(@medium_1_name)
      end

      it 'should restrict acces to un-owned books and media' do
        @user.owned_books.should_not include @books[1]
        @user.owned_books.should_not include @books[2]

        @user.owned_media.should_not include @books[1].media.find_by_name(@medium_1_name)
        @user.owned_media.should_not include @books[2].media.find_by_name(@medium_1_name)
      end

      it 'should be an owner of book' do
        @books[0].owners.should include @user
        @books[1].owners.should_not include @user
      end
    end

    context 'when book option with two medias has been purchased' do
      before do
        @user = Fabricate :user
        Fabricate :purchase, book_option: @books[2].options.find_by_name(@option_3_name), user: @user
      end

      it 'should give user access to book and both mediums' do
        @user.owned_books.should include @books[2]

        @user.owned_media.should include @books[2].media.find_by_name(@medium_1_name)
        @user.owned_media.should include @books[2].media.find_by_name(@medium_2_name)
      end

      it 'should restrict acces to un-owned books and media' do
        @user.owned_books.should_not include @books[0]
        @user.owned_books.should_not include @books[1]

        @user.owned_media.should_not include @books[0].media.find_by_name(@medium_1_name)
        @user.owned_media.should_not include @books[1].media.find_by_name(@medium_1_name)
      end
    end

    context 'when two books have been purchased with different options' do
      before do
        @user = Fabricate :user
        @option_1 = @books[0].options.find_by_name(@option_1_name)
        @option_2 = @books[1].options.find_by_name(@option_2_name)
        Fabricate :purchase, book_option: @option_1, user: @user
        Fabricate :purchase, book_option: @option_2, user: @user
      end

      it 'should give access to both books and medias' do
        @user.owned_books.should include @books[0]
        @user.owned_books.should include @books[1]

        @user.owned_media.should include @option_1.media.first
        @user.owned_media.should include @option_2.media.first
      end

      it 'should restrict acces to un-owned books and media' do
        @user.owned_books.should_not include @books[2]
      end
      
      it 'should tell book/media if its owned by user' do
        @books[0].owners.should include @user
        @books[1].owners.should include @user
        @books[2].owners.should_not include @user

        @books[0].media.find_by_name(@medium_1_name).should be_owned_by @user
        @books[0].media.find_by_name(@medium_2_name).should_not be_owned_by @user

        @books[1].media.find_by_name(@medium_1_name).should_not be_owned_by @user
        @books[1].media.find_by_name(@medium_2_name).should be_owned_by @user
      end

    end
  end
end
