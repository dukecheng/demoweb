using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using System.Text;
using System.IO;
using Microsoft.AspNetCore.Hosting;

namespace demoweb.Controllers
{
    public class DevController : Controller
    {
        [AllowAnonymous]
        public async Task<IActionResult> BuildInfo([FromServices]IHostingEnvironment hostingEnvironment)
        {
            StringBuilder sbBuildInfo = new StringBuilder();
            foreach (var filePath in Directory.GetFiles(hostingEnvironment.ContentRootPath, "build*.txt"))
            {
                var fileInfo = new FileInfo(filePath);
                if (fileInfo.Exists)
                {
                    sbBuildInfo.AppendLine($"File: {fileInfo.Name}");
                    sbBuildInfo.Append(await System.IO.File.ReadAllTextAsync(fileInfo.FullName, Encoding.UTF8));
                    sbBuildInfo.AppendLine($"==================== END FILE {fileInfo.Name} ====================");
                }
            }
            var result = sbBuildInfo.ToString();
            return Content(string.IsNullOrWhiteSpace(result) ? "no build info" : result);
        }
    }
}
