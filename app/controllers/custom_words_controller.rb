class CustomWordsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  
  def index
    @word_form = CustomWordForm.initialize_form
    @terminologies = @word_form.build_custom_words
  end

  def create
    @word_form = CustomWordForm.new(params[:custom_word_form])
    flash[:notice] = (@word_form.disable_custom_words ? t('flash1') : t('flash2'))
    @word_form.save_translations
    @terminologies = @word_form.build_custom_words
    render 'index'
  end
end
