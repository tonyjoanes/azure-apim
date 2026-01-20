using Microsoft.AspNetCore.Mvc;
using SampleAPI.Models;

namespace SampleAPI.Controllers;

/// <summary>
/// Users API endpoints
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public class UsersController : ControllerBase
{
    private static readonly List<User> _users = new()
    {
        new User { Id = 1, Email = "john.doe@example.com", FirstName = "John", LastName = "Doe" },
        new User { Id = 2, Email = "jane.smith@example.com", FirstName = "Jane", LastName = "Smith" },
        new User { Id = 3, Email = "bob.johnson@example.com", FirstName = "Bob", LastName = "Johnson" }
    };

    private readonly ILogger<UsersController> _logger;

    public UsersController(ILogger<UsersController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Get all users
    /// </summary>
    /// <returns>List of users</returns>
    /// <response code="200">Returns the list of users</response>
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<User>), StatusCodes.Status200OK)]
    public ActionResult<IEnumerable<User>> GetAll()
    {
        _logger.LogInformation("Getting all users");
        return Ok(_users);
    }

    /// <summary>
    /// Get a specific user by ID
    /// </summary>
    /// <param name="id">User ID</param>
    /// <returns>User details</returns>
    /// <response code="200">Returns the user</response>
    /// <response code="404">User not found</response>
    [HttpGet("{id}")]
    [ProducesResponseType(typeof(User), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public ActionResult<User> GetById(int id)
    {
        _logger.LogInformation("Getting user with ID: {UserId}", id);

        var user = _users.FirstOrDefault(u => u.Id == id);

        if (user == null)
        {
            _logger.LogWarning("User with ID {UserId} not found", id);
            return NotFound(new { message = $"User with ID {id} not found" });
        }

        return Ok(user);
    }

    /// <summary>
    /// Create a new user
    /// </summary>
    /// <param name="request">User creation request</param>
    /// <returns>Created user</returns>
    /// <response code="201">User created successfully</response>
    /// <response code="400">Invalid request</response>
    [HttpPost]
    [ProducesResponseType(typeof(User), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public ActionResult<User> Create([FromBody] CreateUserRequest request)
    {
        _logger.LogInformation("Creating new user: {Email}", request.Email);

        if (string.IsNullOrEmpty(request.Email))
        {
            return BadRequest(new { message = "Email is required" });
        }

        if (_users.Any(u => u.Email.Equals(request.Email, StringComparison.OrdinalIgnoreCase)))
        {
            return BadRequest(new { message = "User with this email already exists" });
        }

        var user = new User
        {
            Id = _users.Max(u => u.Id) + 1,
            Email = request.Email,
            FirstName = request.FirstName,
            LastName = request.LastName,
            RegisteredAt = DateTime.UtcNow,
            IsActive = true
        };

        _users.Add(user);

        return CreatedAtAction(nameof(GetById), new { id = user.Id }, user);
    }

    /// <summary>
    /// Delete a user
    /// </summary>
    /// <param name="id">User ID</param>
    /// <returns>No content</returns>
    /// <response code="204">User deleted successfully</response>
    /// <response code="404">User not found</response>
    [HttpDelete("{id}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult Delete(int id)
    {
        _logger.LogInformation("Deleting user with ID: {UserId}", id);

        var user = _users.FirstOrDefault(u => u.Id == id);

        if (user == null)
        {
            _logger.LogWarning("User with ID {UserId} not found", id);
            return NotFound(new { message = $"User with ID {id} not found" });
        }

        _users.Remove(user);
        return NoContent();
    }
}
