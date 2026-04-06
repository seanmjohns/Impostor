# Impostor
The classic Impostor social-deduction word game.

> **Quick Start**: See [QUICKSTART.md](QUICKSTART.md) for a 30-second setup guide!

## Features

- **Session-based gameplay**: Create and join games with unique game codes
- **Real-time player list**: See all players in the game, updates automatically
- **Host controls**: Kick players, start rounds, and manage the game
- **Intelligent role assignment**: Ensures at least 1 impostor 95% of the time
- **Voting-based word skipping**: Players can vote to skip difficult words
- **Real-time backend**: Go-based backend for fast, responsive gameplay
- **Mobile-friendly**: Clean, responsive UI that works on all devices

## Project Structure

```
.
├── cmd/server/          # Server entry point
├── internal/
│   ├── models/          # Data models
│   ├── game/            # Game logic
│   ├── handlers/        # HTTP handlers
│   └── wordlist/        # Word list management
├── wordlists/           # Word list files
├── index.html           # Web interface
└── Makefile            # Build commands
```

## Development

```bash
# Build
make build

# Run
make run

# Run tests
make test              # Run all unit tests
make test-verbose      # Run with verbose output

# Format code
make fmt
```

### Testing

The project has comprehensive unit tests covering:
- Game creation and player management (12 player limit)
- Host reassignment when host leaves
- Role assignment algorithm
- Word skipping with notifications
- Session management and security

See **[TESTING.md](TESTING.md)** for detailed testing documentation.

```bash
# Run all tests
make test

# Run specific package tests
go test ./internal/models -v
go test ./internal/game -v
go test ./internal/wordlist -v

# Integration tests
./test_host_reassignment.sh
./test_word_skip_notification.sh
./test_player_order.sh
```

## Deploying 

Project resources are deployed via terraform. 

Install terraform locally: https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

Install the AWS CLI V2: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Assume privileged role in AWS account:

`aws login --profile seanmjohns1` (requires Access Key and Access Secret)

Deploy it:

`make deploy`

You will be prompted for confirmation of terraform changes during the terraform apply. You should see a forced replacement (or not forced if you've changed some values), of the EC2 instance. **Of course, if you see other changes, please ensure that they are expected.** For more information, see `terraform/README.md`. 