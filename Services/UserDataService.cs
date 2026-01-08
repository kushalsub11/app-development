using Week8.Models;

namespace Week8.Services;

public class UserDataService
{
    public List<User> UsersList { get; set; } = new();

    public void AddUser(User user)
    {
        user.Id = UsersList.Count + 1;
        UsersList.Add(user);
    }
}