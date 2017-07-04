class TagsController < ApplicationController
  def show
    @tag = Tag.find_by(title: params[:id])
    @videos = @tag.videos.paginate(page: params[:page])
  end

  def autocomplete
    render json: Tag.like(params[:q]).map { |tag| { id: tag.id, text: tag.title } }
  end
end
