class TagsController < ApplicationController
  before_filter :login_required
  filter_access_to :all
  in_place_edit_with_validation_for :tag, :name
  def index
    @tags = Tag.paginate(:select=>'tags.name,tags.id, count(taggings.id)>0 as tagging_count',:joins=>"LEFT OUTER JOIN `taggings` ON taggings.tag_id = tags.id",:group=>'tags.id',:page => params[:page], :per_page=>10)
    if request.xhr?
      render(:update) do |page|
        page.replace_html'list',:partial=>'tag_list'
      end
    end
  end

  def show
    @tag = Tag.find(params[:id])
    @books = Book.paginate(:joins => [:taggings], :conditions =>["taggings.tag_id = ?",@tag.id],:page => params[:page], :per_page=>10)
    @count = @books.total_entries
    if request.xhr?
      render(:update) do |page|
        page.replace_html'list',:partial=>'list_books'
      end
    end
  end

  def search_tag_ajax
    @tags = Tag.paginate(:conditions => ["name like ?","%#{params[:query]}%"],:page => params[:page], :per_page=>10)
    if request.xhr?
      render(:update) do |page|
        page.replace_html'list',:partial=>'search_tag_ajax'
      end
    end
  end

  def destroy
    tag=Tag.find(params[:id])
    if tag.destroy
      flash[:notice] = "#{t('flash1')}"
    else
      flash[:notice] = t('error_occured')
    end
    redirect_to tags_path
  end
end
