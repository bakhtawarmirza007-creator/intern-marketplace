// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TaskMarketplace {
    
    enum TaskStatus { Open, Proposed, Completed, Disputed }

    struct Task {
        uint256 id;
        address payable client;
        address payable selectedIntern;
        string description; 
        uint256 budget;
        uint256 highestBid;
        TaskStatus status;
        bool isPaid;
    }

    struct Bid {
        address payable intern;
        uint256 bidAmount;
        string proposalHash; 
    }

    uint256 public taskCount;
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => Bid[]) public taskBids;

    event TaskCreated(uint256 indexed taskId, address client, uint256 budget);
    event BidPlaced(uint256 indexed taskId, address intern, uint256 bidAmount);
    event BidAccepted(uint256 indexed taskId, address intern);
    event TaskCompleted(uint256 indexed taskId);

    modifier onlyClient(uint256 _taskId) {
        require(tasks[_taskId].client == msg.sender, "Only the client can perform this action");
        _;
    }

    function createTask(string memory _description) external payable {
        require(msg.value > 0, "Budget must be greater than 0");

        taskCount++;
        tasks[taskCount] = Task({
            id: taskCount,
            client: payable(msg.sender),
            selectedIntern: payable(address(0)),
            description: _description,
            budget: msg.value,
            highestBid: 0,
            status: TaskStatus.Open,
            isPaid: false
        });

        emit TaskCreated(taskCount, msg.sender, msg.value);
    }

    function placeBid(uint256 _taskId, string memory _proposalHash) external {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Open || task.status == TaskStatus.Proposed, "Task is not open for bidding");
        require(msg.sender != task.client, "Clients cannot bid on their own tasks");

        taskBids[_taskId].push(Bid({
            intern: payable(msg.sender),
            bidAmount: task.budget, 
            proposalHash: _proposalHash
        }));

        task.status = TaskStatus.Proposed;

        emit BidPlaced(_taskId, msg.sender, task.budget);
    }

    function acceptBid(uint256 _taskId, uint256 _bidIndex) external onlyClient(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.status == TaskStatus.Proposed, "Task is not in bidding stage");
        
        Bid memory winningBid = taskBids[_taskId][_bidIndex];
        task.selectedIntern = winningBid.intern;
        task.status = TaskStatus.Open; 

        emit BidAccepted(_taskId, winningBid.intern);
    }

    function completeTask(uint256 _taskId) external onlyClient(_taskId) {
        Task storage task = tasks[_taskId];
        require(task.selectedIntern != address(0), "No intern assigned to this task");
        require(!task.isPaid, "Task already paid out");

        task.status = TaskStatus.Completed;
        task.isPaid = true;

        task.selectedIntern.transfer(task.budget);

        emit TaskCompleted(_taskId);
    }

    function getBids(uint256 _taskId) external view returns (Bid[] memory) {
        return taskBids[_taskId];
    }
}