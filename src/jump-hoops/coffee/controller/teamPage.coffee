angular.module 'ahaLuminateControllers'
  .controller 'TeamPageCtrl', [
    '$scope'
    '$rootScope'
    '$location'
    '$filter'
    '$timeout'
    '$uibModal'
    'APP_INFO'
    'TeamraiserTeamService'
    'TeamraiserParticipantService'
    'TeamraiserCompanyService'
    'ZuriService'
    'TeamraiserTeamPageService'
    ($scope, $rootScope, $location, $filter, $timeout, $uibModal, APP_INFO, TeamraiserTeamService, TeamraiserParticipantService, TeamraiserCompanyService, ZuriService, TeamraiserTeamPageService) ->
      $scope.teamId = $location.absUrl().split('team_id=')[1].split('&')[0]
      $scope.teamParticipants = []
      $rootScope.teamName = ''
      $scope.eventDate = ''
      $scope.participantCount = ''
      $scope.studentsPledgedTotal = ''
      $scope.activity1amt = ''
      $scope.activity2amt = ''
      $scope.activity3amt = ''
      
      ZuriService.getZooTeam $scope.teamId,
        error: (response) ->
          $scope.studentsPledgedTotal = 0
          $scope.activity1amt = 0
          $scope.activity2amt = 0
          $scope.activity3amt = 0
        success: (response) ->
          $scope.studentsPledgedTotal = response.data.studentsPledged
          studentsPledgedActivities = response.data.studentsPledgedByActivity
          if studentsPledgedActivities['1']
            $scope.activity1amt = studentsPledgedActivities['1'].count
          else
            $scope.activity1amt = 0
          if studentsPledgedActivities['2']
            $scope.activity2amt = studentsPledgedActivities['2'].count
          else
            $scope.activity2amt = 0
          if studentsPledgedActivities['3']
            $scope.activity3amt = studentsPledgedActivities['3'].count
          else
            $scope.activity3amt = 0
      
      setTeamProgress = (amountRaised, goal) ->
        $scope.teamProgress = 
          amountRaised: if amountRaised then Number(amountRaised) else 0
          goal: if goal then Number(goal) else 0
        $scope.teamProgress.amountRaisedFormatted = $filter('currency')($scope.teamProgress.amountRaised / 100, '$').replace '.00', ''
        $scope.teamProgress.goalFormatted = $filter('currency')($scope.teamProgress.goal / 100, '$').replace '.00', ''
        $scope.teamProgress.percent = 0
        if not $scope.$$phase
          $scope.$apply()
        $timeout ->
          percent = $scope.teamProgress.percent
          if $scope.teamProgress.goal isnt 0
            percent = Math.ceil(($scope.teamProgress.amountRaised / $scope.teamProgress.goal) * 100)
          if percent > 100
            percent = 100
          $scope.teamProgress.percent = percent
          if not $scope.$$phase
            $scope.$apply()
        , 500
      
      getTeamData = ->
        TeamraiserTeamService.getTeams 'team_id=' + $scope.teamId, 
          error: ->
            setTeamProgress()
          success: (response) ->
            teamInfo = response.getTeamSearchByInfoResponse?.team
            companyId = teamInfo.companyId
            $scope.participantCount = teamInfo.numMembers
            
            if not teamInfo
              setTeamProgress()
            else
              setTeamProgress teamInfo.amountRaised, teamInfo.goal
            
            TeamraiserCompanyService.getCompanies 'company_id=' + companyId, 
              success: (response) ->
                coordinatorId = response.getCompaniesResponse?.company.coordinatorId
                eventId = response.getCompaniesResponse?.company.eventId
                
                TeamraiserCompanyService.getCoordinatorQuestion coordinatorId, eventId
                  .then (response) ->
                    $scope.eventDate = response.data.coordinator.event_date
      getTeamData()
      
      setTeamParticipants = (participants, totalNumber, totalFundraisers) ->
        $scope.teamParticipants.participants = participants or []
        $scope.teamParticipants.totalNumber = totalNumber or 0
        $scope.teamParticipants.totalFundraisers = totalFundraisers or 0
        if not $scope.$$phase
          $scope.$apply()
      
      getTeamParticipants = ->
        TeamraiserParticipantService.getParticipants 'team_name=' + encodeURIComponent('%%%') + '&first_name=' + encodeURIComponent('%%%') + '&last_name=' + encodeURIComponent('%%%') + '&list_filter_column=reg.team_id&list_filter_text=' + $scope.teamId + '&list_sort_column=total&list_ascending=false&list_page_size=50', 
            error: (response) ->
              setTeamMembers()
            
            success: (response) ->
              $scope.studentsRegisteredTotal = response.getParticipantsResponse.totalNumberResults
              participants = response.getParticipantsResponse?.participant
              if participants
                participants = [participants] if not angular.isArray participants
                teamParticipants = []
                totalFundraisers = 0
                angular.forEach participants, (participant) ->
                  if participant.amountRaised > 1
                    participant.amountRaised = Number participant.amountRaised
                    participant.amountRaisedFormatted = $filter('currency')(participant.amountRaised / 100, '$').replace '.00', ''
                    participant.name.last = participant.name.last.substring(0,1)+'.'
                    teamParticipants.push participant
                    totalFundraisers++
                totalNumberParticipants = response.getParticipantsResponse.totalNumberResults
                setTeamParticipants teamParticipants, totalNumberParticipants, totalFundraisers
      getTeamParticipants()
      
      $scope.teamPhoto1IsDefault = true
      
      $scope.editTeamPhoto1 = ->
        $scope.editTeamPhoto1Modal = $uibModal.open
          scope: $scope
          templateUrl: APP_INFO.rootPath + 'dist/jump-hoops/html/modal/editTeamPhoto1.html'
      
      $scope.closeTeamPhoto1Modal = ->
        $scope.editTeamPhoto1Modal.close()
      
      $scope.cancelEditTeamPhoto1 = ->
        $scope.closeTeamPhoto1Modal()
      
      $scope.deleteTeamPhoto1 = (e) ->
        if e
          e.preventDefault()
        # TODO
      
      window.trPageEdit =
        uploadPhotoError: (response) ->
          errorResponse = response.errorResponse
          photoType = errorResponse.photoType
          photoNumber = errorResponse.photoNumber
          errorCode = errorResponse.code
          errorMessage = errorResponse.message
          
          # if photoNumber is '1'
            # TODO
        uploadPhotoSuccess: (response) ->
          successResponse = response.successResponse
          photoType = successResponse.photoType
          photoNumber = successResponse.photoNumber
          
          TeamraiserTeamPageService.getTeamPhoto
            error: (response) ->
              # TODO
            success: (response) ->
              photoItems = response.getTeamPhotoResponse?.photoItem
              if photoItems
                photoItems = [photoItems] if not angular.isArray photoItems
                angular.forEach photoItems, (photoItem) ->
                  photoUrl = photoItem.customUrl
                  # if photoItem.id is '1'
                    # TODO
              $scope.closeTeamPhoto1Modal()
  ]