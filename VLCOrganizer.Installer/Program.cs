namespace VLCOrganizer.Installer
{
    internal static class Program
    {
        /// <summary>
        ///  The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            // Enable visual styles
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // Check if we're running as admin and show warning if not
            if (!IsRunningAsAdmin())
            {
                var result = MessageBox.Show(
                    "⚠️ ATENÇÃO: Este programa não está sendo executado como Administrador.\n\n" +
                    "Para instalar/desinstalar o menu de contexto, são necessários privilégios de administrador.\n\n" +
                    "Deseja continuar mesmo assim? (Você poderá tentar novamente como administrador)",
                    "Privilégios de Administrador",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Warning
                );

                if (result == DialogResult.No)
                {
                    return;
                }
            }

            Application.Run(new MainForm());
        }

        private static bool IsRunningAsAdmin()
        {
            try
            {
                using var identity = System.Security.Principal.WindowsIdentity.GetCurrent();
                var principal = new System.Security.Principal.WindowsPrincipal(identity);
                return principal.IsInRole(System.Security.Principal.WindowsBuiltInRole.Administrator);
            }
            catch
            {
                return false;
            }
        }
    }
}