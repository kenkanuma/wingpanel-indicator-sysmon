/*-
 * Copyright (c) 2020 Tudor Plugaru (https://github.com/PlugaruT/wingpanel-monitor)
 * Copyright (c) 2021 Fernando Casas Schössow (https://github.com/casasfernando/wingpanel-indicator-sysmon)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA.
 *
 * Authored by: Tudor Plugaru <plugaru.tudor@gmail.com>
 *              Fernando Casas Schössow <casasfernando@outlook.com>
 */

namespace WingpanelSystemMonitor {
    public class TogglesWidget : Gtk.Box {
        private const int ROW_COUNT = 6;

        private Gtk.Separator settings_separator;
        private Granite.SwitchModelButton icon_only_switch;
        private Granite.SwitchModelButton indicator;

        private string[] widget_keys = { "cpu", "cpu-temp", "ram", "network", "disk", "workspace" };
        private Gtk.Box[] rows = new Gtk.Box[ROW_COUNT];
        private Gtk.Button[] up_buttons = new Gtk.Button[ROW_COUNT];
        private Gtk.Button[] down_buttons = new Gtk.Button[ROW_COUNT];

        public unowned Settings settings { get; construct set; }

        public TogglesWidget (Settings settings) {
            Object (settings: settings, hexpand: true, orientation: Gtk.Orientation.VERTICAL, spacing: 6);
        }

        construct {
            string[] show_settings_keys = {
                "show-cpu", "show-cpu-temp", "show-ram", "show-network", "show-disk", "show-workspace"
            };
            string[] labels = {
                _("CPU usage"), _("CPU temperature"), _("RAM usage"),
                _("Network throughput"), _("Disk throughput"), _("Workspace number")
            };

            icon_only_switch = new Granite.SwitchModelButton (_("Show indicator icon only"));
            icon_only_switch.set_active (settings.get_boolean ("icon-only"));
            settings_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            indicator = new Granite.SwitchModelButton (_("Show indicator"));
            indicator.set_active (settings.get_boolean ("display-indicator"));

            settings.bind ("display-indicator", indicator, "active", SettingsBindFlags.DEFAULT);
            settings.bind ("icon-only", icon_only_switch, "active", SettingsBindFlags.DEFAULT);
            settings.bind ("icon-only", settings_separator, "visible", SettingsBindFlags.INVERT_BOOLEAN);

            add (indicator);
            add (icon_only_switch);
            add (settings_separator);

            for (int i = 0; i < ROW_COUNT; i++) {
                var row_switch = new Granite.SwitchModelButton (labels[i]);
                row_switch.set_active (settings.get_boolean (show_settings_keys[i]));
                settings.bind (show_settings_keys[i], row_switch, "active", SettingsBindFlags.DEFAULT);

                var up_button = new Gtk.Button.from_icon_name ("go-up-symbolic", Gtk.IconSize.MENU);
                up_button.tooltip_text = _("Move up");
                up_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

                var down_button = new Gtk.Button.from_icon_name ("go-down-symbolic", Gtk.IconSize.MENU);
                down_button.tooltip_text = _("Move down");
                down_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

                unowned string key = widget_keys[i];
                up_button.clicked.connect (() => move_widget (key, -1));
                down_button.clicked.connect (() => move_widget (key, 1));

                var row = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
                row.pack_start (up_button, false, false);
                row.pack_start (down_button, false, false);
                row.pack_start (row_switch, true, true);

                settings.bind ("icon-only", row, "visible", SettingsBindFlags.INVERT_BOOLEAN);

                rows[i] = row;
                up_buttons[i] = up_button;
                down_buttons[i] = down_button;

                add (row);
            }

            reorder_rows ();
            settings.changed["widgets-order"].connect (reorder_rows);
        }

        private int index_of_key (string key) {
            for (int i = 0; i < widget_keys.length; i++) {
                if (widget_keys[i] == key) {
                    return i;
                }
            }
            return -1;
        }

        private void move_widget (string key, int direction) {
            string[] order = settings.get_strv ("widgets-order");
            int index = -1;
            for (int i = 0; i < order.length; i++) {
                if (order[i] == key) {
                    index = i;
                    break;
                }
            }

            int new_index = index + direction;
            if (index == -1 || new_index < 0 || new_index >= order.length) {
                return;
            }

            string temp = order[index];
            order[index] = order[new_index];
            order[new_index] = temp;

            settings.set_strv ("widgets-order", order);
        }

        private void reorder_rows () {
            string[] order = settings.get_strv ("widgets-order");

            for (int i = 0; i < order.length; i++) {
                int key_index = index_of_key (order[i]);
                if (key_index == -1) {
                    continue;
                }
                reorder_child (rows[key_index], -1);
                up_buttons[key_index].sensitive = (i != 0);
                down_buttons[key_index].sensitive = (i != order.length - 1);
            }
        }
    }
}
