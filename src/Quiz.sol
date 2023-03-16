// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz{
    struct Quiz_item {
      uint id;
      string question;
      string answer;
      uint min_bet;
      uint max_bet;
   }

    // mapping(address => uint256)[] public bets;
    // 우선은 이중 매핑으로 진행....다른거 하고 시간남으면 이중 아닌걸로 시도...
    mapping(uint256=>mapping(address => uint256)) public bets;
    // 총 베팅에서 얻은 돈
    uint public vault_balance;

    // 누가 권한이 있는지 확인용..?
    address public owner;    
    uint public quiz_cnt;
    // quiz list
    mapping(uint => Quiz_item) public quiz_list;
    // 계좌
    mapping(address => uint256) public balances;
 
    constructor () {
        owner = msg.sender;
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function addQuiz(Quiz_item memory q) public {
        require(msg.sender == owner, "sender is not the owner");
        quiz_cnt++;
        quiz_list[q.id] = q;
    }

    function getAnswer(uint quizId) public view returns (string memory){
        // require(msg.sender == owner, "sender is not the owner");
        return quiz_list[quizId].answer;
    }

    // quizId로 해당 quiz_item을 반환하는 함수
    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        require(msg.sender == owner, "sender is not the owner");
        Quiz_item memory q = quiz_list[quizId];
        q.answer = "";
        return q;
    }

    function getQuizNum() public view returns (uint){
        return quiz_cnt;
    }
    
    // 이게 뭐하는 함수인지부터..
    // sender로부터 ether 받고 그걸 bets에 추가?
    // 조건1) 이때 배팅한 금액이 min보단 크고 max보다는 작아야함
    // 그후 bet에 추가 어케 추가하쥐....
    function betToPlay(uint quizId) public payable {
        require(msg.sender == owner, "sender is not the owner");
        Quiz_item memory q = quiz_list[quizId];
        uint256 bet = msg.value;
        require(bet >= q.min_bet, "bet is smaller than min bet");
        require(bet <= q.max_bet, "bet is larger than max bet");
        // 베팅할 돈 저장
        bets[quizId-1][msg.sender] += bet;
    }

    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        require(msg.sender == owner, "sender is not the owner");
        string memory answer = quiz_list[quizId].answer;
        bool result = keccak256(bytes(answer)) == keccak256(bytes(ans));
        // 맞췄을경우 - 베팅한 것의 2배를 돌려줌
        if(result){
            balances[msg.sender] += bets[quizId-1][msg.sender] * 2;
            bets[quizId-1][msg.sender] = 0;
        }
        // 틀렸을경우 - vault_balance에 추가
        else{            
            vault_balance += bets[quizId-1][msg.sender];
            bets[quizId-1][msg.sender] = 0;
        }
        return result;
    }

    receive() external payable {
    }

    // 여태 모은걸 꺼내는 함수
    // 왜 안되지..??? transfer, call 에서 자꾸 EVM error: Revert
    // 해결 -> receive()함수가 필요함
    function claim() public {
        require(msg.sender == owner, "sender is not the owner");
        // 이 함수를 호출한 사람의 계좌 내역을 가져옴.
        uint256 amount = balances[msg.sender];
        // 계좌 내역 clear
        balances[msg.sender] = 0;
        // 함수를 호출한 주소에게 돈 보냄.        
        payable(msg.sender).transfer(amount);
    }
}
