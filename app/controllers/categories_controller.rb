# encoding: utf-8

class CategoriesController < ApplicationController

  requires_authentication
  requires_moderator except: [:index, :show]

  respond_to :html, :xml, :json

  before_action :load_categories, only: [:index]
  before_action :load_category,   only: [:show, :edit, :update, :destroy]
  before_action :verify_viewable, only: [:show, :edit, :update, :destroy]

  def index
    respond_with(@categories)
  end

  def show
    respond_with(@category) do |format|
      format.html do
        @discussions = @category.discussions.viewable_by(current_user).page(params[:page]).for_view
        respond_with_exchanges(@discussions)
      end
    end
  end

  def new
    respond_with(@category = Category.new)
  end

  def edit
    respond_with(@category)
  end

  def create
    @category = Category.new(category_params)
    respond_with(@category) do |format|
      if @category.save
        format.html { successful_update("The <em>#{@category.name}</em> category was created") }
      else
        flash.now[:notice] = "Couldn't save your category, did you fill in all required fields?"
        format.html { render action: :new }
      end
    end
  end

  def update
    respond_with(@category) do |format|
      if @category.update_attributes(category_params)
        format.html { successful_update("The <em>#{@category.name}</em> category was saved") }
      else
        flash.now[:notice] = "Couldn't save your category, did you fill in all required fields?"
        format.html { render action: :edit }
      end
    end
  end

  private

  def category_params
    params.require(:category).permit(:name, :description)
  end

  def successful_update(message)
    flash[:notice] = message
    redirect_to categories_url and return
  end

  def load_categories
    @categories = Category.viewable_by(current_user)
  end

  def load_category
    begin
      @category = Category.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_error 404 and return
    end
  end

  def verify_viewable
    unless @category.viewable_by?(current_user)
      render_error 403 and return
    end
  end

end
