# frozen_string_literal: true

class Api::V1::NotificationsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:notifications' }, except: [:clear, :dismiss]
  before_action -> { doorkeeper_authorize! :write, :'write:notifications' }, only: [:clear, :dismiss]
  before_action :require_user!
  after_action :insert_pagination_headers, only: :index

  DEFAULT_NOTIFICATIONS_LIMIT = 15

  def index
    logger.info "NotificationsController::index接口调用开始"
    # @notifications = load_notifications
    # render json: @notifications, each_serializer: REST::NotificationSerializer, relationships: StatusRelationshipsPresenter.new(target_statuses_from_notifications, current_user&.account_id)
    # 展示之前先调用外部接口鉴权
    if require_check
      logger.info "NotificationsController::index require_check 鉴权成功"
      @notifications = load_notifications
      render json: @notifications, each_serializer: REST::NotificationSerializer, relationships: StatusRelationshipsPresenter.new(target_statuses_from_notifications, current_user&.account_id)
    else
      @notifications = ""
      render plain: "NotificationsController::index require_check index接口鉴权失败"
    end
  end

  def show
    logger.info "NotificationsController::show接口调用开始"
    @notification = current_account.notifications.without_suspended.find(params[:id])
    render json: @notification, serializer: REST::NotificationSerializer
    # 展示之前先调用外部接口鉴权
    # if require_check
    #   @notification = current_account.notifications.without_suspended.find(params[:id])
    #   render json: @notification, serializer: REST::NotificationSerializer
    # else
    #   render plain: "show接口鉴权失败"
    # end
  end

  def clear
    logger.info "NotificationsController::clear接口调用开始"
    current_account.notifications.delete_all
    render_empty
  end

  def dismiss
    logger.info "NotificationsController::dismiss接口调用开始"
    current_account.notifications.find_by!(id: params[:id]).destroy!
    render_empty
  end

  private

  def load_notifications
    logger.info "NotificationsController::load_notifications"
    notifications = browserable_account_notifications.includes(from_account: :account_stat).to_a_paginated_by_id(
      limit_param(DEFAULT_NOTIFICATIONS_LIMIT),
      params_slice(:max_id, :since_id, :min_id)
    )
    Notification.preload_cache_collection_target_statuses(notifications) do |target_statuses|
      cache_collection(target_statuses, Status)
    end
  end

  def browserable_account_notifications
    logger.info "NotificationsController::browserable_account_notifications"
    current_account.notifications.without_suspended.browserable(exclude_types, from_account)
  end

  def target_statuses_from_notifications
    logger.info "NotificationsController::target_statuses_from_notifications"
    @notifications.reject { |notification| notification.target_status.nil? }.map(&:target_status)
  end

  def insert_pagination_headers
    logger.info "NotificationsController::insert_pagination_headers"
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    logger.info "NotificationsController::next_path"
    unless @notifications.empty?
      api_v1_notifications_url pagination_params(max_id: pagination_max_id)
    end
  end

  def prev_path
    logger.info "NotificationsController::prev_path"
    unless @notifications.empty?
      api_v1_notifications_url pagination_params(min_id: pagination_since_id)
    end
  end

  def pagination_max_id
    @notifications.last.id
  end

  def pagination_since_id
    @notifications.first.id
  end

  def exclude_types
    val = params.permit(exclude_types: [])[:exclude_types] || []
    val = [val] unless val.is_a?(Enumerable)
    val
  end

  def from_account
    params[:account_id]
  end

  def pagination_params(core_params)
    params.slice(:limit, :exclude_types).permit(:limit, exclude_types: []).merge(core_params)
  end

  def require_check
    parm = {
      "UserName" => "will2"
    }.to_json
    resp = send_request("http://8.135.2.89:10001/test",parm)
    logger.info "require_check::send_request resp ===================== #{resp}"
    if resp['ret'] == 0
      return true
    else
      return false
    end
  end

  def send_request(url,parm)
    uri = URI(url)
    http = Net::HTTP.new(uri.host,uri.port)
    req = Net::HTTP::Post.new(uri.path,initheader = {'Content-Type' => 'application/json'})
    req.body = parm
    res = http.request(req)
    return JSON.parse(res.body)
  end

end
