# The demo page you can open in a browser, and a bare page rendering just the
# three helpers for the tests to look at.
class PagesController < ApplicationController
  layout false

  def demo
    @records = Consently::ConsentRecord.order(id: :desc).limit(5).to_a
  end

  # Back to a first visit: the cookie goes, the log goes, the banner returns.
  def reset
    cookies.delete(Consently.config.cookie_name, path: Consently.config.cookie_path)
    Consently::ConsentRecord.delete_all

    redirect_to demo_path(locale: params[:locale])
  end

  # Named cookie_policy, not cookies: an action called `cookies` would
  # override ActionController#cookies and take the whole app down with it.
  def cookie_policy
  end

  def show
  end

  # Stands in for a thank-you page: the ecommerce helper fed with objects that
  # are not hashes, which is the case the shape mapping exists for.
  def checkout
    @items = [ EcommerceTest::LineItem.new(sku: "TB-001", name: "Straight track", price: 12.45, quantity: 2, category: "Track") ]
  end
end
