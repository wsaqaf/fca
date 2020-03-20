class MediaController < ApplicationController
  before_action :check_if_signed_in
  before_action :find_medium, only: [:show, :edit, :update, :destroy]
  before_action :define_types


  def index
    if (params[:sort].present?)
      @sort_msg=sort_bar("Media",params[:sort])
    else
      @sort_msg=sort_bar("Media","td")
    end
    if (params[:term].present?)
      @media = Medium.order(:name).where("(media.sharing_mode=1 OR media.user_id="+current_user.id.to_s+") AND name like ?", "%#{params[:term]}%")
      render json: @media.map(&:name).uniq; return
    elsif (params[:filter]=="r")
      qry="(media.sharing_mode=1 OR media.user_id="+current_user.id.to_s+") AND media.id in (SELECT medium_id FROM medium_reviews WHERE medium_reviews.medium_review_sharing_mode=1 AND medium_reviews.medium_review_verdict IS NOT NULL)"
      @filter_msg=filter_bar("Media","r")
    elsif (params[:filter]=="m")
      qry="media.user_id="+current_user.id.to_s
      @filter_msg=filter_bar("Media","m")
    elsif (params[:filter]=="u")
      qry="(media.sharing_mode=1 OR media.user_id="+current_user.id.to_s+") AND media.id in (SELECT medium_id FROM medium_reviews WHERE medium_reviews.user_id="+current_user.id.to_s+")"
      @filter_msg=filter_bar("Media","u")
    elsif (params[:filter]=="n")
      qry="(media.sharing_mode=1 OR media.user_id="+current_user.id.to_s+") AND NOT EXISTS (SELECT medium_id FROM medium_reviews WHERE media.id=medium_reviews.medium_id AND ((medium_reviews.medium_review_sharing_mode=1 AND medium_reviews.medium_review_verdict IS NOT NULL) OR medium_reviews.user_id="+current_user.id.to_s+"))"
      @filter_msg=filter_bar("Media","n")
    elsif (params[:q].present?)
      @filter_msg=filter_bar("Media","a")
      qry="(media.sharing_mode=1 OR media.user_id="+current_user.id.to_s+") AND (lower(name) like lower('%"+params[:q]+"%') or lower(description) like lower('%"+params[:q]+"%') or lower(url_preview) like lower('%"+params[:q]+"%'))"
    else
      @filter_msg=filter_bar("Media","a")
      if (params[:sort]=="r" or params[:sort]=="rp" or params[:sort]=="rn")
        remove_unsure="";
        if (params[:sort]!="r")
          remove_unsure=" AND medium_reviews.medium_review_verdict!=0 "
        end
        tmp=Medium.joins(:medium_reviews).where("(media.sharing_mode=1 OR media.user_id="+current_user.id.to_s+") AND media.id=medium_reviews.medium_id and medium_reviews.medium_review_sharing_mode=1 and medium_reviews.medium_review_verdict IS NOT NULL"+remove_unsure).group("media.id").order(sort_statement("medium",params[:sort]))
        @total_count=tmp.count.length
      else
        if qry.nil? then qry="media.sharing_mode=1 OR media.user_id="+current_user.id.to_s; end
        tmp=Medium.where(qry).order("created_at DESC")
        @total_count=tmp.count
      end
       @pagy, @media = pagy(tmp, items: 10)
       return
     end
   if (params[:sort]=="r" or params[:sort]=="rp" or params[:sort]=="rn")
     remove_unsure="";
     if (params[:sort]!="r")
       remove_unsure=" AND medium_reviews.medium_review_verdict!=0 "
     end
     tmp=Medium.joins(:medium_reviews).where("(media.sharing_mode=1 OR media.user_id="+current_user.id.to_s+") AND media.id=medium_reviews.medium_id and medium_reviews.medium_review_sharing_mode=1 and medium_reviews.medium_review_verdict IS NOT NULL"+remove_unsure).group("media.id").order(sort_statement("medium",params[:sort]))
     @total_count=tmp.count.length
   else
     if qry.nil? then qry="media.sharing_mode=1 OR media.user_id="+current_user.id.to_s; end
     tmp=Medium.where(qry).order("created_at DESC")
     @total_count=tmp.count
   end
   @pagy, @media = pagy(tmp, items: 10)
  end

  def show
    begin
      @medium_type=@all_medium_types[@medium.medium_type.to_s]
    rescue
      redirect_to root_path
      return
    end
    @warning_msg=""
    dependent_reviews=MediumReview.where("medium_id = ?",@medium.id).count("id")
    if (dependent_reviews>0)
      @warning_msg= t('warning_del_dependents', count:dependent_reviews.to_s)+".\n"
    end
    @warning_msg=@warning_msg+"\n"+t('warning_del')
  end

  def new
    @medium = current_user.media.build
  end

  def create
    @medium = current_user.media.build(medium_params)

    begin
      if @medium.save
          redirect_to media_path
      else
          render 'new'
      end
    rescue
      render 'new'
    end
  end

  def edit
    if current_user.id!=@medium.user_id && current_user.id!=1
      redirect_to medium_path(@medium)
    end
  end

  def update
    if current_user.id!=@medium.user_id && current_user.id!=1
      redirect_to medium_path(@medium)
      return
    end
    if @medium.update(medium_params)
      redirect_to medium_path(@medium)
    else
      render 'edit'
    end
  end

  def destroy
    Claim.where("medium_id = ?",@medium.id).update_all(medium_id: nil)
    MediumReview.where("medium_id = ?",@medium.id).destroy_all
    @medium.destroy
    redirect_to media_path
  end

  private

    def medium_params
      params.require(:medium).permit(:name, :url, :medium_type, :description, :sharing_mode, :url_preview)
    end

    def find_medium
        @medium = Medium.where("id=? AND (media.sharing_mode=1 OR media.user_id="+current_user.id.to_s+")",params[:id]).first
    end

    def define_types
      @all_medium_types={"1"=>t('medium_type_social_media'),"2"=>t('medium_type_news'),"3"=>t('medium_type_im'),"4"=>t('medium_type_video'),"5"=>t('medium_type_blog'),"100"=>t('medium_type_other')}
      @medium_types=[]
      @medium_types.push(['Select',''])
      @all_medium_types.each do |key, value|
        @medium_types.push([value,key])
      end
    end

end
