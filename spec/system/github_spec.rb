require 'rails_helper'

RSpec.describe "Github", type: :system do
  with_rubydoc_config({}) do
    context "GET /" do
      before do
        Library.gem.delete_all
        create_list(:github, 10)
        create(:gem, name: "yard", versions: [ "1.0.0", "2.0.0", "3.0.0", "4.0.0", "5.0.0" ])
        create(:github, name: "abc", owner: "xyz", versions: [ "main" ])
        create(:github, name: "bcd", owner: "xyz", versions: [ "main" ])
      end

      context "when no featured libraries are configured" do
        it do
          visit root_path
          expect(page).to have_selector("h2", text: "GitHub Projects Listing")
          expect(page).to have_no_selector("h2", text: "Featured Libraries Listing")
          expect(page).to have_link(text: "xyz/abc", href: yard_github_path("xyz", "abc"))
          expect(page).not_to have_selector(".alpha a", text: "Latest")
          expect(page).to have_selector(".alpha .selected", text: "Latest")
          expect(page).to have_selector("nav .selected", text: "GitHub")

          (?a.. ?z).each do |letter|
            expect(page).to have_selector(".alpha a", text: letter.chr.upcase)
          end
        end
      end

      context "when featured libraries are configured" do
        with_rubydoc_config(libraries: { featured: { yard: "gem" } }) do
          it do
            visit root_path(letter: "b")
            expect(page).to have_selector(".alpha .selected", text: "B")
            expect(page).to have_selector("h2", text: "Featured Libraries Listing")
            expect(page).to have_link(text: "yard", href: yard_gems_path("yard"))
            expect(page).to have_link(text: "4.0.0", href: yard_gems_path("yard", "4.0.0"))
            expect(page).to have_link(text: "3.0.0", href: yard_gems_path("yard", "3.0.0"))
            expect(page).to have_link(text: "2.0.0", href: yard_gems_path("yard", "2.0.0"))

            expect(page).to have_selector("h2", text: "GitHub Projects Listing")
            expect(page).to have_link(text: "xyz/bcd", href: yard_github_path("xyz", "bcd"))
          end
        end
      end
    end

    context "POST /+" do
      context "fails to add an invalid project" do
        it do
          visit root_path

          expect(page).to have_selector(".top-nav a", text: "Add Project")
          click_on "Add Project"

          expect(page).to have_selector("#modal form", visible: true)
          within("#modal form") do
            fill_in "GitHub URL", with: "invalid_url"
            click_on "Add Project"
          end

          expect(page).to have_selector("form .errors", text: "URL is invalid")
        end
      end

      context "fails to add invalid commit" do
        it do
          visit root_path

          expect(page).to have_selector(".top-nav a", text: "Add Project")
          click_on "Add Project"

          expect(page).to have_selector("#modal form", visible: true)
          within("#modal form") do
            fill_in "Commit (optional)", with: "/"
            click_on "Add Project"
          end

          expect(page).to have_selector("form .errors", text: "URL is invalid and commit is invalid")
        end
      end

      context "succeeds to add a valid project" do
        it do
          visit root_path

          expect(page).to have_selector(".top-nav a", text: "Add Project")
          click_on "Add Project"

          expect(page).to have_selector("#modal form", visible: true)
          within("#modal form") do
            fill_in "GitHub URL", with: "https://github.com/docmeta/rubydoc.info"
            click_on "Add Project"
          end

          expect(page).to have_current_path(yard_github_path("docmeta", "rubydoc.info"))
        end
      end
    end
  end
end
