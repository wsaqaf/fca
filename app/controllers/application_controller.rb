class ApplicationController < ActionController::Base
    include Pagy::Backend
    before_action :set_locale

    private

    def set_locale
       I18n.default_locale = params[:locale] if params[:locale].present?
       @pagy_locale = params[:locale] || 'en'
       @no_turbolinks="false"
    end

    protect_from_forgery with: :exception

    before_action :configure_permitted_parameters, if: :devise_controller?
    before_action :set_current_user

    autocomplete :user, :affiliation

    def set_current_user
      User.current_user = current_user
    end

    protected

    def configure_permitted_parameters
        devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :affiliation, :email, :password])
        devise_parameter_sanitizer.permit(:account_update, keys: [:name, :affiliation, :email, :password, :current_password])
    end

    def check_if_signed_in
      if !user_signed_in?
        redirect_to new_user_session_path
        return
      end
    end

      def filter_bar(page,filter_option)
        f={"a"=>"","m"=>"","r"=>"","u"=>"","n"=>""}
        page1=page.downcase
        page2=page
        if (page=="Srcs") then page2="Sources"; end
        f.each do |key, value|
            if key==filter_option then f[key]="selected"; end
        end
        return "<select id='filter'><option value='"+page1+"' "+f['a']+">"+t('all')+" "+t(page2.downcase)+"</option><option value='?filter=m' "+f['m']+">"+t(page2.downcase)+t('you_created')+"</option><option value='?filter=r' "+f['r']+">"+t(page2.downcase)+t('been_reviewed')+"</option><option value='?filter=u' "+f['u']+">"+t(page2.downcase)+t('you_reviewed')+"</option><option value='?filter=n' "+f['n']+">"+t(page2.downcase)+t('with_no_reviews')+"</option></select>\n<script>$(function(){$('#filter').on('change',function(){{window.location=$(this).val();}return false;});});</script>"
      end

      def sort_statement(page,sorting)
        if page=="claim"
           page2=""
        else
          page2=page+"_"
        end

        case sorting
        when "r"
          return "count("+page+"_reviews."+page2+"review_verdict) DESC"
        when "rp"
          return "sum("+page+"_reviews."+page2+"review_verdict-2) DESC"
        when "rn"
          return "sum("+page+"_reviews."+page2+"review_verdict-2) ASC"
        when "rt"
          return page+"_reviews.updated_at DESC,"+page+"_reviews.created_at DESC"
        end
      end

      def sort_bar(page,sort_option)
        s={"td"=>"","r"=>"","rt"=>"","rp"=>"","rn"=>""}
        page1=page.downcase
        page2=page
        if (page=="Srcs") then page2="Sources"; end
        s.each do |key, value|
            if key==sort_option then s[key]="selected"; end
        end
        return t('sort_by')+": <select id='sort'><option value='?sort=td' "+s['td']+">"+t('sort_by_time')+"</option><option value='?sort=rt' "+s['rt']+">"+t('sort_by_review_time')+"</option><option value='?sort=r' "+s['r']+">"+t('sort_by_reviews')+"</option><option value='?sort=rp' "+s['rp']+">"+t('sort_by_pos_reviews')+"</option><option value='?sort=rn' "+s['rn']+">"+t('sort_by_neg_reviews')+
        "</option><select>\n<script>$(function(){$('#sort').on('change',function(){{window.location=$(this).val();}return false;});});</script>"
      end

    def linkpreview
        url = params[:url]
        preview = LinkPreviewParser.parse(url) # returns a Hash
        respond_to do |format|
            format.json { render :json => preview }
        end
    end

    class Thumbnail
      require 'link_thumbnailer'
      attr_reader :url
      def initialize(url)
        @url = url
      end
      def title
        thumbnailer.try(:title)
      end
      def description
        thumbnailer.try(:description)
      end
      def images
        thumbnailer.try(:images)
      end
      def videos
        thumbnailer.try(:images)
      end
      def favicon
        thumbnailer.try(:favicon)
      end

      private
      def thumbnailer
        @thumbnailer ||= LinkThumbnailer.generate(url, verify_ssl: false)
      rescue LinkThumbnailer::Exceptions
        nil
      end
    end

end
