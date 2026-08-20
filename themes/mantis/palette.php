<?php
/*
	Mantis palette for the FusionPBX theme.

	css.php builds every rule from the variables set in its defaults block, and
	those defaults read global theme settings that the mybrand theme also uses.
	Overriding the variables here keeps the Mantis look self contained: nothing in
	the database changes, so switching the template back leaves the other theme
	exactly as it was.

	Values come from the Mantis design tokens in css/tokens.css, which were
	resolved by running the template's own theme code rather than sampled by eye.
*/

//type
	$mantis_font = "'Public Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif";

//palette
	$mantis_primary        = '#1677ff';
	$mantis_primary_dark   = '#0958d9';
	$mantis_primary_light  = '#69b1ff';
	$mantis_primary_lighter= '#e6f4ff';
	$mantis_paper          = '#ffffff';
	$mantis_canvas         = '#fafafb';
	$mantis_subtle         = '#f5f5f5';
	$mantis_hover          = '#fafafa';
	$mantis_border_card    = '#e6ebf1';
	$mantis_divider        = '#f0f0f0';
	$mantis_border_input   = '#d9d9d9';
	$mantis_text           = '#262626';
	$mantis_text_secondary = '#8c8c8c';
	$mantis_radius         = '8px';
	$mantis_radius_sm      = '4px';

/* Shell --------------------------------------------------------------------- */
//the drawer is light in Mantis, the dark rail is what FusionPBX ships
	$menu_main_background_image        = null;
	$menu_main_background_color        = $mantis_paper;
	$menu_main_background_color_hover  = $mantis_primary_lighter;
	$menu_main_shadow_color            = 'none';
	$menu_main_border_color            = $mantis_border_card;
	$menu_main_border_size             = '0';
	$menu_main_border_radius           = '0';
	$menu_main_text_font               = $mantis_font;
	$menu_main_text_size               = '14px';
	$menu_main_text_color              = '#595959';
	$menu_main_text_color_hover        = $mantis_primary;
	$menu_main_toggle_color            = '#595959';
	$menu_main_toggle_color_hover      = $mantis_primary;
	$menu_main_icon_color              = $mantis_text_secondary;
	$menu_main_icon_color_hover        = $mantis_primary;
	$menu_brand_text_color             = $mantis_text;
	$menu_brand_text_color_hover       = $mantis_primary;
	$menu_brand_text_size              = '16px';

//top bar
	$body_header_background_color         = $mantis_paper;
	$body_header_shadow_color             = 'none';
	$body_header_brand_text_color         = $mantis_text;
	$body_header_brand_text_color_hover   = $mantis_primary;
	$body_header_brand_text_size          = '16px';
	$body_header_text_link_color          = $mantis_text;
	$body_header_text_link_color_hover    = $mantis_primary;

/* Page ---------------------------------------------------------------------- */
	$body_color          = $mantis_canvas;
	$body_border_radius  = '0';
	$body_shadow_color   = 'none';
	$body_text_color     = $mantis_text;
	$body_text_size      = '14px';
	$body_text_font      = $mantis_font;
	$body_icon_color     = $mantis_text_secondary;
	$body_icon_color_hover = $mantis_primary;
	$pre_text_color      = $mantis_text;
	$text_link_color     = $mantis_primary;
	$text_link_color_hover = $mantis_primary_dark;

	$heading_text_color  = $mantis_text;
	$heading_text_size   = '20px';
	$heading_text_font   = $mantis_font;
	$heading_count_background_color = $mantis_primary;
	$heading_count_text_color = $mantis_paper;
	$heading_count_text_font  = $mantis_font;
	$heading_count_text_size  = '12px';
	$heading_count_text_weight = '600';
	$heading_count_border_radius = '10px';
	$heading_count_padding = '2px 8px';

	$footer_background_color = 'transparent';
	$footer_color = $mantis_text_secondary;
	$footer_border_radius = '0';

/* Cards --------------------------------------------------------------------- */
	$card_background_color = $mantis_paper;
	$card_border_color     = $mantis_border_card;
	$card_border_size      = '1px';
	$card_border_radius    = $mantis_radius;
	$card_shadow_color     = 'transparent';
	$card_shadow_size      = '0';
	$card_padding          = '20px';

/* Lists --------------------------------------------------------------------- */
//Mantis tables are not striped, so every row shade is the same paper colour
	$table_heading_text_color       = $mantis_text;
	$table_heading_text_size        = '12px';
	$table_heading_text_font        = $mantis_font;
	$table_heading_background_color = $mantis_subtle;
	$table_heading_border_color     = $mantis_divider;
	$table_heading_padding          = '12px 16px';

	$table_row_text_color            = $mantis_text;
	$table_row_text_font             = $mantis_font;
	$table_row_text_size             = '14px';
	$table_row_text_link_color       = $mantis_primary;
	$table_row_text_link_color_hover = $mantis_primary_dark;
	$table_row_border_color          = $mantis_divider;
	$table_row_background_color_light  = $mantis_paper;
	$table_row_background_color_medium = $mantis_paper;
	$table_row_background_color_dark   = $mantis_paper;
	$table_row_background_color_hover  = $mantis_hover;
	$table_row_padding                 = '12px 16px';

/* Detail forms --------------------------------------------------------------- */
//the label column is a quiet cell in Mantis, not a filled bar
	$form_table_label_background_color = 'transparent';
	$form_table_label_border_color     = $mantis_divider;
	$form_table_label_border_radius    = '0';
	$form_table_label_padding          = '14px 16px';
	$form_table_label_text_color       = $mantis_text;
	$form_table_label_text_font        = $mantis_font;
	$form_table_label_text_size        = '14px';
	$form_table_label_required_background_color = 'transparent';
	$form_table_label_required_border_color     = $mantis_divider;
	$form_table_label_required_text_color       = $mantis_text;
	$form_table_label_required_text_weight      = '600';

	$form_table_field_background_color = 'transparent';
	$form_table_field_border_color     = $mantis_divider;
	$form_table_field_border_radius    = '0';
	$form_table_field_padding          = '10px 16px';
	$form_table_field_text_color       = $mantis_text;
	$form_table_field_text_font        = $mantis_font;
	$form_table_field_text_size        = '14px';
	$form_table_heading_padding        = '16px 16px 8px 16px';

/* Inputs --------------------------------------------------------------------- */
	$input_height     = '32px';
	$input_text_font  = $mantis_font;
	$input_text_size  = '14px';

/* Buttons -------------------------------------------------------------------- */
	$button_height                       = '32px';
	$button_padding                      = '6px 14px';
	$button_border_size                  = '1px';
	$button_border_color                 = $mantis_primary;
	$button_border_radius                = $mantis_radius_sm;
	$button_background_color             = $mantis_primary;
	$button_background_color_bottom      = $mantis_primary;
	$button_text_font                    = $mantis_font;
	$button_text_color                   = $mantis_paper;
	$button_text_weight                  = '500';
	$button_text_size                    = '14px';
	$button_border_color_hover           = $mantis_primary_dark;
	$button_background_color_hover       = $mantis_primary_dark;
	$button_background_color_bottom_hover= $mantis_primary_dark;
	$button_text_color_hover             = $mantis_paper;

/* Domain selector ------------------------------------------------------------ */
	$domain_selector_background_color       = $mantis_paper;
	$domain_selector_shadow_color           = '0 2px 8px rgba(0,0,0,0.10)';
	$domain_selector_title_color            = $mantis_text;
	$domain_selector_title_color_hover      = $mantis_primary;
	$domain_selector_list_background_color  = $mantis_paper;
	$domain_selector_list_border_color      = $mantis_border_card;
	$domain_selector_list_divider_color     = $mantis_divider;

/* Inputs, deeper ------------------------------------------------------------- */
	$input_background_color        = $mantis_paper;
	$input_text_color              = $mantis_text;
	$input_text_placeholder_color  = '#bfbfbf';
	$input_border_color            = $mantis_border_input;
	$input_border_color_hover      = $mantis_primary;
	$input_border_color_focus      = $mantis_primary;
	$input_border_color_hover_focus= $mantis_primary;
	$input_border_radius           = $mantis_radius_sm;
	$input_border_size             = '1px';
	$input_border_style            = 'solid';
	$input_shadow_inner_color      = 'transparent';
	$input_shadow_inner_color_focus= 'transparent';
	$input_shadow_outer_color      = 'transparent';
	$input_shadow_outer_color_focus= 'transparent';
//Mantis marks focus with a soft primary ring rather than a hard outline
	$input_outline_color             = 'transparent';
	$input_outline_color_hover       = 'transparent';
	$input_outline_color_focus       = 'rgba(22, 119, 255, 0.2)';
	$input_outline_color_hover_focus = 'rgba(22, 119, 255, 0.2)';
	$input_outline_size              = '0';
	$input_outline_size_hover        = '0';
	$input_outline_size_focus        = '2px';
	$input_outline_size_hover_focus  = '2px';
	$input_outline_style             = 'solid';
	$input_outline_radius            = $mantis_radius_sm;
	$input_toggle_switch_background_color_true  = $mantis_primary;
	$input_toggle_switch_background_color_false = $mantis_border_input;
	$input_toggle_switch_handle_color           = $mantis_paper;
	$pwstrength_background_color                = $mantis_subtle;

/* Action bar ----------------------------------------------------------------- */
//flat while the page sits at the top, a hairline and lift once it sticks
	$action_bar_background        = 'transparent';
	$action_bar_border_top        = 'none';
	$action_bar_border_right      = 'none';
	$action_bar_border_bottom     = 'none';
	$action_bar_border_left       = 'none';
	$action_bar_border_radius     = '0';
	$action_bar_shadow            = 'none';
	$action_bar_background_scroll    = $mantis_paper;
	$action_bar_border_top_scroll    = 'none';
	$action_bar_border_right_scroll  = 'none';
	$action_bar_border_bottom_scroll = '1px solid ' . $mantis_divider;
	$action_bar_border_left_scroll   = 'none';
	$action_bar_border_radius_scroll = '0';
	$action_bar_shadow_scroll        = '0 1px 4px rgba(0, 0, 0, 0.08)';

/* Sub menus ------------------------------------------------------------------ */
	$menu_sub_background_color       = $mantis_paper;
	$menu_sub_background_color_hover = $mantis_primary_lighter;
	$menu_sub_border_color           = $mantis_border_card;
	$menu_sub_border_size            = '1px';
	$menu_sub_border_radius          = $mantis_radius;
	$menu_sub_shadow_color           = 'rgba(0,0,0,0.10)';
	$menu_sub_text_color             = '#595959';
	$menu_sub_text_color_hover       = $mantis_primary;
	$menu_sub_text_font              = $mantis_font;
	$menu_sub_text_size              = '14px';
	$logout_icon_color               = '#595959';
	$logout_icon_color_hover         = $mantis_primary;

/* Domain selector entries ---------------------------------------------------- */
	$domain_active_text_color         = $mantis_text;
	$domain_active_text_color_hover   = $mantis_primary;
	$domain_active_desc_text_color    = $mantis_text_secondary;
	$domain_inactive_text_color       = $mantis_text_secondary;
	$domain_inactive_text_color_hover = $mantis_primary;
	$domain_inactive_desc_text_color  = '#bfbfbf';
	$header_domain_color_hover        = $mantis_primary;
	$header_user_color_hover          = $mantis_primary;

/* Messages ------------------------------------------------------------------- */
	$message_default_color             = $mantis_text;
	$message_default_background_color  = $mantis_subtle;
	$message_positive_color            = '#237804';
	$message_positive_background_color = '#f6ffed';
	$message_negative_color            = '#a8071a';
	$message_negative_background_color = '#fff1f0';
	$message_alert_color               = '#ad6800';
	$message_alert_background_color    = '#fffbe6';

/* Modal ---------------------------------------------------------------------- */
	$modal_background_color              = $mantis_paper;
	$modal_corner_radius                 = $mantis_radius;
	$modal_padding                       = '20px';
	$modal_shade_color                   = 'rgba(0, 0, 0, 0.5)';
	$modal_shadow                        = '0 2px 8px rgba(0,0,0,0.10)';
	$modal_title_color                   = $mantis_text;
	$modal_title_font                    = $mantis_font;
	$modal_message_color                 = $mantis_text;
	$modal_close_color                   = $mantis_text_secondary;
	$modal_close_color_hover             = $mantis_text;
	$modal_close_background_color        = 'transparent';
	$modal_close_background_color_hover  = $mantis_subtle;
	$modal_close_corner_radius           = $mantis_radius_sm;

/* Dashboard widgets ---------------------------------------------------------- */
//frame only, the per widget colours still come from the database
	$dashboard_border_color              = $mantis_border_card;
	$dashboard_border_color_hover        = $mantis_border_card;
	$dashboard_border_radius             = $mantis_radius;
	$dashboard_background_color          = $mantis_paper;
	$dashboard_shadow_color              = 'transparent';
	$dashboard_detail_background_color   = $mantis_paper;
	$dashboard_detail_shadow_color       = 'transparent';
	$dashboard_label_text_color          = $mantis_text_secondary;
	$dashboard_label_text_color_hover    = $mantis_text_secondary;
	$dashboard_label_text_font           = $mantis_font;
	$dashboard_label_text_size           = '12px';
	$dashboard_label_background_color    = 'transparent';
	$dashboard_label_background_color_hover = 'transparent';
	$dashboard_label_text_shadow_color   = 'transparent';
	$dashboard_number_text_color         = $mantis_text;
	$dashboard_number_text_color_hover   = $mantis_text;
	$dashboard_number_text_font          = $mantis_font;
	$dashboard_number_background_color   = 'transparent';
	$dashboard_number_background_color_hover = 'transparent';
	$dashboard_number_text_shadow_color  = 'transparent';
	$dashboard_number_text_shadow_color_hover = 'transparent';
	$dashboard_number_title_text_color   = $mantis_text_secondary;
	$dashboard_number_title_text_font    = $mantis_font;
	$dashboard_number_title_text_shadow_color = 'transparent';
	$dashboard_footer_background_color   = $mantis_subtle;
	$dashboard_footer_background_color_hover = $mantis_divider;
	$dashboard_footer_dots_color         = $mantis_border_input;
	$dashboard_footer_dots_color_hover   = $mantis_text_secondary;

/* Login ---------------------------------------------------------------------- */
	$login_body_background_color = $mantis_paper;
	$login_body_border_color     = $mantis_border_card;
	$login_body_border_size      = '1px';
	$login_body_border_style     = 'solid';
	$login_body_border_radius    = $mantis_radius;
	$login_body_shadow_color     = 'rgba(0,0,0,0.08)';
	$login_body_padding          = '32px';
	$login_text_color            = $mantis_text;
	$login_text_font             = $mantis_font;
	$login_link_text_color       = $mantis_primary;
	$login_link_text_color_hover = $mantis_primary_dark;
	$login_link_text_font        = $mantis_font;
	$login_input_background_color   = $mantis_paper;
	$login_input_text_color         = $mantis_text;
	$login_input_text_font          = $mantis_font;
	$login_input_text_placeholder_color = '#bfbfbf';
	$login_input_border_color            = $mantis_border_input;
	$login_input_border_color_hover      = $mantis_primary;
	$login_input_border_color_focus      = $mantis_primary;
	$login_input_border_color_hover_focus= $mantis_primary;
	$login_input_border_radius   = $mantis_radius_sm;
	$login_input_border_size     = '1px';
	$login_input_border_style    = 'solid';
	$login_input_shadow_inner_color       = 'transparent';
	$login_input_shadow_inner_color_focus = 'transparent';
	$login_input_shadow_outer_color       = 'transparent';
	$login_input_shadow_outer_color_focus = 'transparent';
	$login_input_outline_color             = 'transparent';
	$login_input_outline_color_hover       = 'transparent';
	$login_input_outline_color_focus       = 'rgba(22, 119, 255, 0.2)';
	$login_input_outline_color_hover_focus = 'rgba(22, 119, 255, 0.2)';
	$login_input_outline_size              = '0';
	$login_input_outline_size_hover        = '0';
	$login_input_outline_size_focus        = '2px';
	$login_input_outline_size_hover_focus  = '2px';
	$login_input_outline_style             = 'solid';
	$login_input_outline_radius            = $mantis_radius_sm;

/* Operator panel and audio player -------------------------------------------- */
	$operator_panel_border_color          = $mantis_border_card;
	$operator_panel_main_background_color = $mantis_paper;
	$operator_panel_sub_background_color  = $mantis_subtle;
	$operator_panel_user_info             = $mantis_text;
	$operator_panel_caller_info           = $mantis_text;
	$operator_panel_call_info             = $mantis_text_secondary;
	$audio_player_indicator_color         = $mantis_primary;

?>
