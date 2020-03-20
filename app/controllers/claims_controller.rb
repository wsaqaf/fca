class ClaimsController < ApplicationController
  before_action :check_if_signed_in, only: [:show, :edit, :update, :destroy, :new, :create]
  before_action :find_claim, only: [:show, :edit, :update, :destroy]

  def index

    order=""

    if (params[:sort].present?)
      @sort_msg=sort_bar("Claims",params[:sort])
    else
      @sort_msg=sort_bar("Claims","td")
    end
    if (params[:filter]=="r")
      qry="claims.id in (SELECT claim_id FROM claim_reviews WHERE (claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+") AND claim_reviews.review_sharing_mode=1 AND review_verdict IS NOT NULL)"
      @filter_msg=filter_bar("Claims","r")
    elsif (params[:filter]=="m")
      qry="claims.user_id="+current_user.id.to_s
      @filter_msg=filter_bar("Claims","m")
    elsif (params[:filter]=="u")
      qry="claims.id in (SELECT claim_id FROM claim_reviews WHERE (claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+") AND claim_reviews.user_id="+current_user.id.to_s+")"
      @filter_msg=filter_bar("Claims","u")
    elsif (params[:filter]=="n")
      qry="(claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+") AND NOT EXISTS (SELECT claim_id FROM claim_reviews WHERE claims.id=claim_reviews.claim_id AND ((claim_reviews.review_sharing_mode=1 AND claim_reviews.review_verdict IS NOT NULL) OR claim_reviews.user_id="+current_user.id.to_s+"))"
      @filter_msg=filter_bar("Claims","n")
    elsif (params[:q].present?)
      @filter_msg=filter_bar("Claims","a")
      qry=" (claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+") and (lower(title) like lower('%"+params[:q]+"%') or lower(description) like lower('%"+params[:q]+"%') or lower(url_preview) like lower('%"+params[:q]+"%'))"
    elsif (params[:m].present?)
      @filter_msg=filter_bar("Claims","a")
      qry=" (claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+") and medium_id="+params[:m].to_s
    elsif (params[:s].present?)
      @filter_msg=filter_bar("Claims","a")
      qry=" (claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+") and src_id="+params[:s].to_s
    elsif(params[:tag_list].present?)
        output=''
        added=0
        tag_list=params[:tag_list].split(/\s*,\s*/)
        for tag_name in tag_list
            tag=Tag.where("claim_name=?",tag_name).first
            if (tag.nil?) then
                result=Tag.create(claim_name: tag_name);
                if (!result.valid?)
                   output=output+"- "+t('tag_could_not_add')+tag_name+"!<br>"
                else
                   output=output+"- "+tag_name+t('tag_added')+"<br>"
                   added=1
                end
            else
                output=output+"- "+tag_name+t('tag_exists')+"<br>"
                added=1
            end
        end
        if (added==1)
            lst="var result2 = \""+output+"\";";
            output=output+"<br>"+t('tags_added')+"\n<script>\n"+lst+"\n</script>"
        end
        render json: output;
    elsif (params[:refresh_tag_list].present?)
      output=''
      Tag.order('lower(claim_name) ASC').each do |t|
          output=output+'<option value="'+t.id.to_s+'">'+t.claim_name+"</option>\n"
      end
      render json: output;
    elsif (params[:url].present?)
        @filter_msg=""
        output=""
        preview = Thumbnail.new(params[:url])
        imglist=""
        titl=""
        desc=""
        if !preview.blank?
          if !preview.title.nil? and !preview.description.nil?
            i=0
            titl=preview.title
            desc=preview.description
            imglist="var images= ["
            preview.images.each do |img|
              imglist=imglist+"'"+img.src.to_s+"',"
              i=i+1
            end
            if i>1
              imglist="<script>\nvar i=0;\n"+imglist.chomp(',')+"];\n"
              imglist=imglist+"prev.onclick=function(){if(i==0){i="+i.to_s+";};document.getElementById('cimg').src=images[--i];}</script>"
              output=output+"\n"+imglist
              output=output+'<br><a href="#" id="prev">Change thumbnail</a><br><div id="final_url_preview" class="fragment">'
              output=output+'<div style="text-align: left"><img src="'+preview.images.first.src.to_s+'" id="cimg" style="max-width:128px;max-height:75px" />'
            elsif i==1
              output=output+'<br><div id="final_url_preview" class="fragment"><div style="text-align: left"><img src="'+preview.images.first.src.to_s+'" id="cimg" style="max-width:128px;max-height:75px" /><br>'
            elsif is_img(params[:url])
              output=output+'<div id="final_url_preview" class="fragment"><div style="text-align: left"><img src="'+params[:url]+'" id="cimg" style="max-width:128px;max-height:75px" /><br>'
              titl=params[:url]
              desc="URL"
            else
              output=output+'<br><div id="final_url_preview" class="fragment"><div style="text-align: left">'
            end
            url=params[:url]
            if (url.present?)
                begin
                  domain_name=URI.parse(url).host
                  domain_name=domain_name.sub(/^www\./, '')
                rescue
                  domain_name=url
                end
            end
            output=output+"\n<h4><a href=\""+params[:url]+"\" target=_blank>"+titl+"</a></h4><br><i>"+domain_name.to_s+"</i><br><p class=\"text\">"+desc+"</p></div></div>"
          end
      end
        render json: output;
        return
      else
        @filter_msg=filter_bar("Claims","a")
        if params[:tag]
          tmp=Claim.tagged_with(params[:tag])
          @total_count=tmp.count
        elsif (params[:sort]=="r" or params[:sort]=="rp" or params[:sort]=="rn")
          remove_unsure="";
          if (params[:sort]!="r")
            remove_unsure=" AND claim_reviews.review_verdict!=0 "
          end
          tmp=Claim.joins(:claim_reviews).where("claims.id=claim_reviews.claim_id and (claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+") and claim_reviews.review_sharing_mode=1 and claim_reviews.review_verdict IS NOT NULL"+remove_unsure).group("claims.id").order(sort_statement("claim",params[:sort]))
          @total_count=tmp.count.length
        elsif  (params[:sort]=="rt")
          tmp=Claim.joins(:claim_reviews).where("claims.id=claim_reviews.claim_id and (claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+") and claim_reviews.review_sharing_mode=1 and claim_reviews.review_verdict IS NOT NULL").group("claims.id,claim_reviews.updated_at,claim_reviews.created_at").order(sort_statement("claim",params[:sort]))
          @total_count=tmp.count.length
        elsif !user_signed_in?
            return
        else
          if qry.nil? then qry="claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s; end
          tmp=Claim.where(qry).order("created_at DESC")
          @total_count=tmp.count
        end
        @pagy, @claims = pagy(tmp, items: 10)
        return
      end
      if params[:tag]
        tmp=Claim.tagged_with(params[:tag])
        @total_count=tmp.count
      elsif (params[:sort]=="r" or params[:sort]=="rp" or params[:sort]=="rn")
        remove_unsure="";
        if (params[:sort]!="r")
          remove_unsure=" AND src_reviews.src_review_verdict!=0 "
        end
        tmp=Claim.joins(:claim_reviews).where("claims.id=claim_reviews.claim_id and (claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+") and claim_reviews.review_sharing_mode=1 and claim_reviews.review_verdict IS NOT NULL"+remove_unsure).group("claims.id").order(sort_statement("claim",params[:sort]))
        @total_count=tmp.count.length
      elsif  (params[:sort]=="rt")
        tmp=Claim.joins(:claim_reviews).where("claims.id=claim_reviews.claim_id and (claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+") and claim_reviews.review_sharing_mode=1 and claim_reviews.review_verdict IS NOT NULL").group("claims.id,claim_reviews.updated_at,claim_reviews.created_at").order(sort_statement("claim",params[:sort]))
        @total_count=tmp.count.length
      elsif !user_signed_in?
          return
      else
        if qry.nil? then qry="claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s; end
        tmp=Claim.where(qry).order("created_at DESC")
      end
      @total_count=tmp.count
      @pagy, @claims = pagy(tmp, items: 10)
  end

  def show
    @warning_msg=""
    dependent_reviews=ClaimReview.where("claim_id = ?",@claim.id).count("id")
    if (dependent_reviews>0)
      @warning_msg= t('warning_del_dependents', count:dependent_reviews.to_s)+".\n"
    end
    @warning_msg=@warning_msg+"\n"+t('warning_del')
  end

  def new
      @claim = current_user.claims.build
      @srcs = Src.all.map{ |c| [c.name, c.id]}
      @media = Medium.all.map{ |m| [m.name, m.id]}
  end

  def create
    @claim = current_user.claims.build(claim_params)
    if @claim.save
        redirect_to root_path
    else
        render 'new'
    end
  end

  def edit
    if current_user.id!=@claim.user_id && current_user.id!=1
      redirect_to claim_path(@claim)
    end
  end

  def update
    if current_user.id!=@claim.user_id && current_user.id!=1
      redirect_to claim_path(@claim)
      return
    end
    if @claim.update(claim_params)
      redirect_to claim_path(@claim)
    else
      render 'edit'
    end
  end

  def destroy
    ClaimReview.where("claim_id = ?",@claim.id).destroy_all
    Tagging.where("claim_id = ?",@claim.id).destroy_all
    Tag.where.not(id: Tagging.pluck(:tag_id).reject {|x| x.nil?}).destroy_all
    @claim.destroy
    redirect_to root_path
  end

  private

    def is_img(url)
      require 'open-uri'
      str = open(url)
      if str.content_type.to_s.include? "image" or str.content_type.to_s.include? "img"
        return true
      end
      return false
    end

    def claim_params
      params.require(:claim).permit(:id, :title, :medium_name, :src_name, :url, :description, :has_image, :has_video, :has_text, :sharing_mode, :url_preview, :tag_list, :tag, { tag_ids: [] }, :tag_ids)
    end

    def find_claim
        @claim = Claim.where("id=? AND (claims.sharing_mode=1 OR claims.user_id="+current_user.id.to_s+")",params[:id]).first
    end

end
