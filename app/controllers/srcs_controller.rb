class SrcsController < ApplicationController
  before_action :find_src, only: [:show, :edit, :update, :destroy]
  before_action :define_types
  before_action :check_if_signed_in

  def index
    if (params[:sort].present?)
      @sort_msg=sort_bar("Srcs",params[:sort])
    else
      @sort_msg=sort_bar("Srcs","td")
    end
    if (params[:term].present?)
      @srcs = Src.order(:name).where("name like ? AND (srcs.sharing_mode=1 OR srcs.user_id="+current_user.id.to_s+") ", "%#{params[:term]}%")
      render json: @srcs.map(&:name).uniq; return
    elsif (params[:filter]=="r")
      qry="srcs.id in (SELECT src_id FROM src_reviews WHERE (srcs.sharing_mode=1 OR srcs.user_id="+current_user.id.to_s+") AND src_reviews.src_review_sharing_mode=1 AND src_reviews.src_review_verdict IS NOT NULL)"
      @filter_msg=filter_bar("Srcs","r")
    elsif (params[:filter]=="m")
      qry="srcs.user_id="+current_user.id.to_s
      @filter_msg=filter_bar("Srcs","m")
    elsif (params[:filter]=="u")
      qry="srcs.id in (SELECT src_id FROM src_reviews WHERE (srcs.sharing_mode=1 OR srcs.user_id="+current_user.id.to_s+") AND src_reviews.user_id="+current_user.id.to_s+")"
      @filter_msg=filter_bar("Srcs","u")
    elsif (params[:filter]=="n")
      qry="(srcs.sharing_mode=1 OR srcs.user_id="+current_user.id.to_s+") AND NOT EXISTS (SELECT src_id FROM src_reviews WHERE srcs.id=src_reviews.src_id AND ((src_reviews.src_review_sharing_mode=1 AND src_reviews.src_review_verdict IS NOT NULL) OR src_reviews.user_id="+current_user.id.to_s+"))"
      @filter_msg=filter_bar("Srcs","n")
    elsif (params[:q].present?)
      @filter_msg=filter_bar("Srcs","a")
      qry="(srcs.sharing_mode=1 OR srcs.user_id="+current_user.id.to_s+") AND (lower(name) like lower('%"+params[:q]+"%') or lower(description) like lower('%"+params[:q]+"%') or lower(url_preview) like lower('%"+params[:q]+"%'))"
    else
      @filter_msg=filter_bar("Srcs","a")
      if (params[:sort]=="r" or params[:sort]=="rp" or params[:sort]=="rn")
        remove_unsure="";
        if (params[:sort]!="r")
          remove_unsure=" AND src_reviews.src_review_verdict!=0 "
        end
        tmp=Src.joins(:src_reviews).where("(srcs.sharing_mode=1 OR srcs.user_id="+current_user.id.to_s+") AND srcs.id=src_reviews.src_id and src_reviews.src_review_sharing_mode=1 and src_reviews.src_review_verdict IS NOT NULL"+remove_unsure).group("srcs.id").order(sort_statement("src",params[:sort]))
        @total_count=tmp.count.length
      else
        if qry.nil? then qry="srcs.sharing_mode=1 OR srcs.user_id="+current_user.id.to_s; end
        tmp=Src.where(qry).order("created_at DESC")
        @total_count=tmp.count
      end
       @pagy, @srcs = pagy(tmp, items: 10)
       return
     end
   if (params[:sort]=="r" or params[:sort]=="rp" or params[:sort]=="rn")
     remove_unsure="";
     if (params[:sort]!="r")
       remove_unsure=" AND src_reviews.src_review_verdict!=0 "
     end
     tmp=Src.joins(:src_reviews).where("(srcs.sharing_mode=1 OR srcs.user_id="+current_user.id.to_s+") AND srcs.id=src_reviews.src_id and src_reviews.src_review_sharing_mode=1 and src_reviews.src_review_verdict IS NOT NULL"+remove_unsure).group("srcs.id").order(sort_statement("src",params[:sort]))
     @total_count=tmp.count.length
   else
     if qry.nil? then qry="srcs.sharing_mode=1 OR srcs.user_id="+current_user.id.to_s; end
     tmp=Src.where(qry).order("created_at DESC")
     @total_count=tmp.count
   end
     @pagy, @srcs = pagy(tmp, items: 10)
  end

  def show
    begin
      @src_type=@all_src_types[@src.src_type.to_s]
    rescue
      redirect_to root_path
      return
    end
    @warning_msg=""
    dependent_reviews=SrcReview.where("src_id = ?",@src.id).count("id")
    if (dependent_reviews>0)
      @warning_msg= t('warning_del_dependents', count:dependent_reviews.to_s)+".\n"
    end
    @warning_msg=@warning_msg+"\n"+t('warning_del')
  end

  def new
    @src = current_user.srcs.build
  end

  def create
    @src = current_user.srcs.build(src_params)

    begin
      if @src.save
          redirect_to srcs_path
      else
          render 'new'
      end
    rescue
      render 'new'
    end
  end

  def edit
    if current_user.id!=@src.user_id && current_user.id!=1
      redirect_to src_path(@src)
    end
  end

  def update
    if current_user.id!=@src.user_id && current_user.id!=1
      redirect_to src_path(@src)
      return
    end
    if @src.update(src_params)
      redirect_to src_path(@src)
    else
      render 'edit'
    end
  end

  def destroy
    Claim.where("src_id = ?",@src.id).update_all(src_id: nil)
    SrcReview.where("src_id = ?",@src.id).destroy_all
    @src.destroy
    redirect_to srcs_path
  end

  private

    def src_params
      params.require(:src).permit(:name, :url, :src_type, :description, :sharing_mode, :url_preview)
    end

    def find_src
      @src = Src.where("id=? AND (srcs.sharing_mode=1 OR srcs.user_id="+current_user.id.to_s+")",params[:id]).first
    end

    def define_types
      @all_src_types={"1"=>t('src_type_social_person'),"2"=>t('src_type_establishment'),"3"=>t('src_type_website'),"100"=>t('src_type_other'),"0"=>t('src_type_not_sure')}
      @src_types=[]
      @src_types.push(['Select',''])
      @all_src_types.each do |key, value|
        @src_types.push([value,key])
      end
    end

end
