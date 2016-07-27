angular.module 'ahaLuminateControllers'
  .controller 'CompanyPageCtrl', [
    '$scope'
    '$location'
    'TeamraiserCompanyService'
    'TeamraiserTeamService'
    'TeamraiserParticipantService'
    ($scope, $location, TeamraiserCompanyService, TeamraiserTeamService, TeamraiserParticipantService) ->
      $scope.companyId = $location.absUrl().split('company_id=')[1].split('&')[0]
      
      $defaultCompanySummary = angular.element '.js--default-company-summary'
      companyGiftCount = $defaultCompanySummary.find('.company-tally-container--gift-count .company-tally-ammount').text()
      if companyGiftCount is ''
        companyGiftCount = '0'
      $scope.companyProgress = 
        numDonations: companyGiftCount
      
      setCompanyFundraisingProgress = (amountRaised, goal) ->
        $scope.companyProgress.amountRaised = amountRaised or '0'
        $scope.companyProgress.goal = goal or '0'
        if not $scope.$$phase
          $scope.$apply()
      TeamraiserCompanyService.getCompanies 'company_id=' + $scope.companyId, 
        error: ->
          setCompanyFundraisingProgress()
        success: (response) ->
          companyInfo = response.getCompaniesResponse?.company
          if not companyInfo
            setCompanyFundraisingProgress()
          else
            setCompanyFundraisingProgress companyInfo.amountRaised, companyInfo.goal
      
      $defaultCompanyHierarchy = angular.element '.js--default-company-hierarchy'
      $childCompanyLinks = $defaultCompanyHierarchy.find('.trr-td a')
      childCompanies = []
      angular.forEach $childCompanyLinks, (childCompanyLink) ->
        childCompanyUrl = angular.element(childCompanyLink).attr('href')
        childCompanyName = angular.element(childCompanyLink).text()
        if childCompanyUrl.indexOf('company_id=') isnt -1
          childCompanies.push 
            id: childCompanyUrl.split('company_id=')[1].split('&')[0]
            name: childCompanyName
      numCompanies = childCompanies.length + 1
      
      $scope.companyTeams = 
        page: 1
      setCompanyTeams = (teams, totalNumber) ->
        $scope.companyTeams.teams = teams or []
        $scope.companyTeams.totalNumber = totalNumber or 0
        if not $scope.$$phase
          $scope.$apply()
      $scope.childCompanyTeams = 
        companies: []
      addChildCompanyTeams = (companyIndex, companyId, companyName, teams, totalNumber) ->
        $scope.childCompanyTeams.companies[companyIndex] = 
          companyId: companyId or ''
          companyName: companyName or ''
          teams: teams or []
          totalNumber: totalNumber or 0
      setCompanyNumTeams = (numTeams) ->
        $scope.companyProgress.numTeams = numTeams or 0
        if not $scope.$$phase
          $scope.$apply()
      numCompaniesTeamRequestComplete = 0
      numTeams = 0
      TeamraiserTeamService.getTeams 'team_company_id=' + $scope.companyId + '&list_sort_column=total&list_ascending=false&list_page_size=5', 
        error: ->
          setCompanyTeams()
          numCompaniesTeamRequestComplete++
          if numCompaniesTeamRequestComplete is numCompanies
            setCompanyNumTeams numTeams
        success: (response) ->
          setCompanyTeams()
          companyTeams = response.getTeamSearchByInfoResponse?.team
          if companyTeams
            companyTeams = [companyTeams] if not angular.isArray companyTeams
            angular.forEach companyTeams, (companyTeam) ->
              joinTeamURL = companyTeam.joinTeamURL
              if joinTeamURL
                companyTeam.joinTeamURL = joinTeamURL.split('/site/')[1]
            totalNumberTeams = response.getTeamSearchByInfoResponse.totalNumberResults
            setCompanyTeams companyTeams, totalNumberTeams
            numTeams += Number totalNumberTeams
          numCompaniesTeamRequestComplete++
          if numCompaniesTeamRequestComplete is numCompanies
            setCompanyNumTeams numTeams
      angular.forEach childCompanies, (childCompany, childCompanyIndex) ->
        childCompanyId = childCompany.id
        childCompanyName = childCompany.name
        TeamraiserTeamService.getTeams 'team_company_id=' + childCompanyId + '&list_sort_column=total&list_ascending=false&list_page_size=5', 
          error: ->
            addChildCompanyTeams childCompanyIndex, childCompanyId, childCompanyName
            numCompaniesTeamRequestComplete++
            if numCompaniesTeamRequestComplete is numCompanies
              setCompanyNumTeams numTeams
          success: (response) ->
            companyTeams = response.getTeamSearchByInfoResponse?.team
            if not companyTeams
              addChildCompanyTeams childCompanyIndex, childCompanyId, childCompanyName
            else
              companyTeams = [companyTeams] if not angular.isArray companyTeams
              angular.forEach companyTeams, (companyTeam) ->
                joinTeamURL = companyTeam.joinTeamURL
                if joinTeamURL
                  companyTeam.joinTeamURL = joinTeamURL.split('/site/')[1]
              totalNumberTeams = response.getTeamSearchByInfoResponse.totalNumberResults
              addChildCompanyTeams childCompanyIndex, childCompanyId, childCompanyName, companyTeams, totalNumberTeams
              numTeams += Number totalNumberTeams
            numCompaniesTeamRequestComplete++
            if numCompaniesTeamRequestComplete is numCompanies
              setCompanyNumTeams numTeams
      
      $scope.companyParticipants = 
        page: 1
      setCompanyParticipants = (participants, totalNumber) ->
        $scope.companyParticipants.participants = participants or []
        $scope.companyParticipants.totalNumber = totalNumber or 0
        if not $scope.$$phase
          $scope.$apply()
      $scope.childCompanyParticipants = 
        companies: []
      addChildCompanyParticipants = (companyIndex, companyId, companyName, participants, totalNumber) ->
        $scope.childCompanyParticipants.companies[companyIndex] = 
          companyId: companyId or ''
          companyName: companyName or ''
          participants: participants or []
          totalNumber: totalNumber or 0
      setCompanyNumParticipants = (numParticipants) ->
        $scope.companyProgress.numParticipants = numParticipants or 0
        if not $scope.$$phase
          $scope.$apply()
      numCompaniesParticipantRequestComplete = 0
      numParticipants = 0
      TeamraiserParticipantService.getParticipants 'team_name=' + encodeURIComponent('%') + '&list_filter_column=team.company_id&list_filter_text=' + $scope.companyId + '&list_sort_column=total&list_ascending=false&list_page_size=5', 
        error: ->
          setCompanyParticipants()
          numCompaniesParticipantRequestComplete++
          if numCompaniesParticipantRequestComplete is numCompanies
            setCompanyNumParticipants numParticipants
        success: (response) ->
          setCompanyParticipants()
          companyParticipants = response.getParticipantsResponse?.participant
          if companyParticipants
            # TODO: only include participants with a first name
            companyParticipants = [companyParticipants] if not angular.isArray companyParticipants
            angular.forEach companyParticipants, (companyParticipant) ->
              donationUrl = companyParticipant.donationUrl
              if donationUrl
                companyParticipant.donationUrl = donationUrl.split('/site/')[1]
            totalNumberParticipants = response.getParticipantsResponse.totalNumberResults
            setCompanyParticipants companyParticipants, totalNumberParticipants
            numParticipants += Number totalNumberParticipants
          numCompaniesParticipantRequestComplete++
          if numCompaniesParticipantRequestComplete is numCompanies
            setCompanyNumParticipants numParticipants
      angular.forEach childCompanies, (childCompany, childCompanyIndex) ->
        childCompanyId = childCompany.id
        childCompanyName = childCompany.name
        TeamraiserParticipantService.getParticipants 'team_name=' + encodeURIComponent('%') + '&list_filter_column=team.company_id&list_filter_text=' + childCompanyId + '&list_sort_column=total&list_ascending=false&list_page_size=5', 
          error: ->
            addChildCompanyParticipants childCompanyIndex, childCompanyId, childCompanyName
            numCompaniesParticipantRequestComplete++
            if numCompaniesParticipantRequestComplete is numCompanies
              setCompanyNumParticipants numParticipants
          success: (response) ->
            companyParticipants = response.getParticipantsResponse?.participant
            if not companyParticipants
              addChildCompanyParticipants childCompanyIndex, childCompanyId, childCompanyName
            else
              # TODO: only include participants with a first name
              companyParticipants = [companyParticipants] if not angular.isArray companyParticipants
              angular.forEach companyParticipants, (companyParticipant) ->
                donationUrl = companyParticipant.donationUrl
                if donationUrl
                  companyParticipant.donationUrl = donationUrl.split('/site/')[1]
              totalNumberParticipants = response.getParticipantsResponse.totalNumberResults
              addChildCompanyParticipants childCompanyIndex, childCompanyId, childCompanyName, companyParticipants, totalNumberParticipants
              numParticipants += Number totalNumberParticipants
            numCompaniesParticipantRequestComplete++
            if numCompaniesParticipantRequestComplete is numCompanies
              setCompanyNumParticipants numParticipants
  ]