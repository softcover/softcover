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
        @user.books.should include @books[0]
        @user.books.should_not include @books[1]
        @user.books.should_not include @books[2]

        @user.accessible_media.should include @books[0].media.find_by_name(@medium_1_name)
        @user.accessible_media.should_not include @books[1].media.find_by_name(@medium_1_name)
        @user.accessible_media.should_not include @books[2].media.find_by_name(@medium_1_name)
      end
    end

    context 'when book option with two medias has been purchased' do
      before do
        @user = Fabricate :user
        Fabricate :purchase, book_option: @books[2].options.find_by_name(@option_3_name), user: @user
      end

      it 'should give user access to book and both mediums' do
        @user.books.should include @books[2]
        @user.books.should_not include @books[0]
        @user.books.should_not include @books[1]

        @user.accessible_media.should include @books[2].media.find_by_name(@medium_1_name)
        @user.accessible_media.should include @books[2].media.find_by_name(@medium_2_name)

        @user.accessible_media.should_not include @books[0].media.find_by_name(@medium_1_name)
        @user.accessible_media.should_not include @books[1].media.find_by_name(@medium_1_name)
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
        @user.books.should include @books[0]
        @user.books.should include @books[1]
        @user.books.should_not include @books[2]

        @user.accessible_media.should include @option_1.media.first
        @user.accessible_media.should include @option_2.media.first
      end

    end
  end

  it 'should have access to books' do

    #============================================
    # Setup
    #============================================
    

    #============================================
    # user_1 purchases the PDF option of book one
    #============================================

    #===================================================
    # user_2 purchases the Screencast option of book two
    #===================================================
    #user_2 = Fabricate :user
    #Fabricate :purchase, book_option: books[1].options.find_by_name(option_2_name), user: user_2

    #user_2.books.should include books[1]
    #user_2.books.should_not include books[0]
    #user_2.books.should_not include books[2]

    #user_2.accessible_media.should include books[1].media.find_by_name(medium_2_name)
    #user_2.accessible_media.should_not include books[0].media.find_by_name(medium_2_name)
    #user_2.accessible_media.should_not include books[2].media.find_by_name(medium_2_name)

    #===================================================
    # user_3 purchases the Both option of book three
    #===================================================
  end
end
