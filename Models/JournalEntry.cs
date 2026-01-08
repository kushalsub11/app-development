using System;

namespace Week8.Models
{
    public class JournalEntry
    {
        public int Id { get; set; }
        public DateTime Date { get; set; } = DateTime.Today;
        public string Content { get; set; }
        public string PrimaryMood { get; set; } // Required
        public string? SecondaryMood1 { get; set; } // Optional
        public string? SecondaryMood2 { get; set; } // Optional
        public string? Theme { get; set; } // For theme customization
        public string? PasswordHash { get; set; } // For security (hashed)
    }
}