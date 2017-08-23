class VideosController < ApplicationController
  before_action :authorize, except: %i[show]

  def show
    @video = Video.find(params[:id]).decorate
    impressionist(@video)
  end

  def new
    @video = Video.new
  end

  def create
    # Ensure all fields are present.
    if param(:tournament).blank? || param(:aff_school).blank? || param(:neg_school).blank? ||
        param(:aff_debater_one).blank? || param(:neg_debater_one).blank? ||
        param(:year).blank? || param(:tournament).blank? ||
        param(:debate_level).blank? || param(:debate_type).blank?
      redirect_to new_video_path, alert: 'You must complete all required fields.'
      return
    end

    # Find or create tournament.
    tournament = find_or_create_tournament(param(:tournament), param(:year))

    # Find or create schools.
    aff_school = find_or_create_school(param(:aff_school))
    neg_school = find_or_create_school(param(:neg_school))

    # Find or create debaters.
    aff_debater_one = find_or_create_debater(param(:aff_debater_one), aff_school)
    aff_debater_two = find_or_create_debater(param(:aff_debater_two), aff_school)
    neg_debater_one = find_or_create_debater(param(:neg_debater_one), neg_school)
    neg_debater_two = find_or_create_debater(param(:neg_debater_two), neg_school)

    # Find or create teams.
    aff_team = find_or_create_team(aff_debater_one, aff_debater_two, aff_school)
    neg_team = find_or_create_team(neg_debater_one, neg_debater_two, neg_school)

    tags = find_or_create_tags(param(:tags_ids))

    keys = param(:key).split(',').reject!(&:empty?)

    video = Video.create(provider: param(:provider), key: keys, thumbnail: param(:thumbnail), user: current_user, debate_level: param(:debate_level), debate_type: param(:debate_type), tournament: tournament, tags: tags, aff_team: aff_team, neg_team: neg_team)
    video.tags_videos.each do |tv|
      tv.update(user: current_user)
    end

    redirect_to video_path(video)
  end

  def add_tags
    video = Video.find(params[:video_id])

    find_or_create_tags(params[:add_tag][:tags_ids]).each do |tag|
      TagsVideo.create(tag: tag, video: video, user: current_user) unless video.tags.include?(tag)
    end

    redirect_to video_path(video)
  end

  def info
    info = VideoInformationService.link_info(params[:link])
    provider = Video.providers[info[:provider]]
    info = { exists: true } if Video.where('videos.provider = ? and videos.key like ?', provider, "%#{info[:key]}%").count.positive?
    render json: info
  end

  private

  def authorize
    redirect_to root_path, error: 'You must log in first.' unless logged_in?
  end

  def param(key)
    params[:video][key]
  end

  def find_or_create_tournament(id_or_name, year)
    if Tournament.exists?(id_or_name)
      Tournament.find(id_or_name)
    elsif Tournament.where(year: year, name: id_or_name).positive?
      Tournament.find_by(year: year, name: id_or_name)
    else
      Tournament.create(year: year, name: id_or_name)
    end
  end

  def find_or_create_school(id_or_name)
    if School.exists?(id_or_name)
      School.find(id_or_name)
    elsif School.where(name: id_or_name).positive?
      School.find_by(name: id_or_name)
    else
      School.create(name: id_or_name)
    end
  end

  def find_or_create_debater(id_or_name, school)
    return nil if id_or_name.blank?
    if Debater.exists?(id_or_name)
      Debater.find(id_or_name)
    else
      name = id_or_name.split(' ')
      first_name = name.shift
      last_name = name.join(' ')
      if Debater.where(school: school, first_name: first_name, last_name: last_name).positive?
        Debater.find_by(school: school, first_name: first_name, last_name: last_name)
      else
        Debater.create(first_name: first_name, last_name: last_name, school: school)
      end
    end
  end

  def find_or_create_team(debater_one, debater_two, school)
    if Team.with_debaters(debater_one, debater_two).positive?
      Team.with_debaters(debater_one, debater_two).first
    else
      # Ensure debaters are alphabetically ordered.
      if debater_two.last_name < debater_one.last_name
        tmp = debater_one
        debater_one = debater_two
        debater_two = tmp
      end
      Team.create(debater_one_id: debater_one.id, debater_two_id: debater_two.id, school: school)
    end
  end

  def find_or_create_tags(tags_ids)
    tags_ids.split(',').map do |tag|
      next if tag.blank?
      if Tag.exists?(tag)
        Tag.find(tag)
      elsif Tag.where(title: tag.downcase).positive?
        Tag.find_by(title: tag.downcase)
      else
        Tag.create(title: tag.downcase)
      end
    end
  end
end
