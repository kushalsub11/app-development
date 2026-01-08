namespace Week8.Models;

public class User
{
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public int Age { get; set; }
    public DateTime BirthDate { get; set; }
    public string Course { get; set; } = string.Empty;
    public bool AgreeToTerms { get; set; }
}