class SearchesController < ApplicationController
  # GET /searches
  # GET /searches.json
 
 def daily_search
  a = Spider.new
  @list =  a.get_results(params[:wherebox])
  #if request.xhr?
    #render :js => "$('#search_results').html('#{escape_javascript(render(:partial => 'list'))}');"
   #   render :js => "$('.loginform').fadeOut();  $('.result').fadeIn();"
  
 #end
 view = ActionView::Base.new(ActionController::Base.view_paths, {})
view.render(:file => "index.html.erb", :locals => params)
# respond_to do |format|
#     format.html # index.html.erb
#     format.js 
#end
 end
  
 def monthly_search
  a = Spider.new
  @list =  a.get_results(params[:wherebox])
 view = ActionView::Base.new(ActionController::Base.view_paths, {})
view.render(:file => "/searches/monthly.erb") 
  respond_to do |format|
      format.html # index.html.erb
      format.js 
  end
 end

 
 def index
    @searches = Search.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @searches }
    end
  end

  # GET /searches/1
  # GET /searches/1.json
  def show
    @search = Search.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/new
  # GET /searches/new.json
  def new
    @search = Search.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/1/edit
  def edit
    @search = Search.find(params[:id])
  end

  # POST /searches
  # POST /searches.json
  def create
    @search = Search.new(params[:search])

    respond_to do |format|
      if @search.save
        format.html { redirect_to @search, notice: 'Search was successfully created.' }
        format.json { render json: @search, status: :created, location: @search }
      else
        format.html { render action: "new" }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /searches/1
  # PUT /searches/1.json
  def update
    @search = Search.find(params[:id])

    respond_to do |format|
      if @search.update_attributes(params[:search])
        format.html { redirect_to @search, notice: 'Search was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /searches/1
  # DELETE /searches/1.json
  def destroy
    @search = Search.find(params[:id])
    @search.destroy

    respond_to do |format|
      format.html { redirect_to searches_url }
      format.json { head :no_content }
    end
  end
end