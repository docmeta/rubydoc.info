require 'rails_helper'

RSpec.describe "Github", type: :system do
  with_rubydoc_config({}) do
    context "GET /" do
      before do
        Library.gem.delete_all
      end

      context "when no gems are available" do
        it do
          visit gems_path
          expect(page).to have_selector("h2", text: "RubyGems Listing")
          expect(page).to have_selector("nav .selected", text: "RubyGems")

          expect(page).to have_selector(".alpha .selected", text: "A")
          (?b.. ?z).each do |letter|
            expect(page).to have_selector(".alpha a", text: letter.chr.upcase)
          end

          expect(page).to have_selector(".row", text: "No matches found.")
        end
      end

      context "when gems are available" do
        before do
          Library.gem.delete_all
          create(:gem, name: "yard", versions: [ "1.0.0", "2.0.0", "3.0.0", "4.0.0", "5.0.0" ])
        end

        it do
          visit gems_path(letter: "y")
          expect(page).to have_selector(".alpha .selected", text: "Y")
          expect(page).to have_link(text: "yard", href: yard_gems_path("yard"))
          expect(page).to have_link(text: "4.0.0", href: yard_gems_path("yard", "4.0.0"))
          expect(page).to have_link(text: "3.0.0", href: yard_gems_path("yard", "3.0.0"))
          expect(page).to have_link(text: "2.0.0", href: yard_gems_path("yard", "2.0.0"))
        end
      end
    end
  end
end
