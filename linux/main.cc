#include "my_application.h"

int main(int argc, char** argv) {
  // Silence two cosmetic warnings spammed by GTK/AT-SPI on most Linux
  // sessions when the host's accessibility bus / cursor theme is partial:
  //   - "Atk-CRITICAL atk_socket_embed: assertion 'plug_id != NULL' failed"
  //   - "Gdk-Message: Unable to load <name> from the cursor theme"
  // Disabling the AT-SPI bridge here only affects this process. Honors
  // any value the user has already exported.
  g_setenv("NO_AT_BRIDGE", "1", FALSE);
  g_setenv("GTK_A11Y", "none", FALSE);
  // Adwaita ships a complete cursor set, so missing-cursor messages stop.
  g_setenv("XCURSOR_THEME", "Adwaita", FALSE);

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
