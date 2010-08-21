
module Redcar
  module Textmate
    class Bundle
      include Redcar::Observable
      attr_reader :path, :snippets, :preferences
    
      def initialize(path)
        @path = File.expand_path(path)
        info_path = File.join(path, "info.plist")
        if File.exist?(info_path)
          @plist = Plist.xml_to_plist(File.read(info_path))
        end
        @snippets = snippet_paths.map {|path| Snippet.new(path, self.name) }
        @preferences = preference_paths.map {|path| Preference.new(path) }
        add_listener(:refresh_menu) do
          @menus = nil
        end
      end
      
      def name
        @plist["name"]
      end
      
      def uuid
        @plist["uuid"]
      end
      
      def ordering
        @plist["ordering"]
      end
      
      def contact_name
        @plist["contactName"]
      end
      
      def contact_email
        @plist["contactEmailRot13"]
      end
      
      def description
        @plist["description"]
      end
      
      def deleted
        @plist["deleted"]
      end
      
      def main_menu
        @plist["mainMenu"]
      end
      
      def sub_menus
        main_menu["submenus"]
      end
      
      def build_menu(builder)
        snippets
        @menus = nil
        @menus = begin
          if main_menu and main_menu["items"]
            builder.sub_menu name do |m|
              main_menu["items"].each do |item|
                build_menu_from_item(builder, item)
              end
            end
          end
        end
      end
      
      def build_menu_from_item(builder, item)
        if item =~ /^$/
          builder.separator
        elsif sub_menu = sub_menus[item]
          builder.sub_menu(sub_menu["name"]) do |sub_builder|
            sub_menu["items"].each do |sub_item|
              build_menu_from_item(sub_builder, sub_item)
            end
          end
          #sub_menu
        elsif snippet = Textmate.uuid_hash[item] and snippet.is_a?(Textmate::Snippet)
          return unless snippet.name and snippet.name != ""
          add_menu_item(builder,snippet)
        end
      end
      
      def add_menu_item(builder, snippet)
        if snippet.is_a?(Textmate::Snippet)
          builder.item(snippet.to_menu_string) do
            doc = EditView.focussed_edit_view_document
            if doc
              controller = doc.controllers(Snippets::DocumentController).first
              controller.start_snippet!(snippet)
            end
          end
        end
      end
      
      private
      
      def preference_paths
        Dir[File.join(path, "Preferences", "*")]
      end
      
      def snippet_paths
        Dir[File.join(path, "Snippets", "*")]
      end
    end
  end
end